//
//  SocketConnector.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/17.
//
#import "FlappyBaseSession.h"
#import "FlappyStringTool.h"
#import "FlappyApiConfig.h"
#import "FlappyJsonTool.h"
#import "FlappyDataBase.h"
#import "FlappyNetTool.h"
#import "FlappySender.h"
#import "FlappySocket.h"
#import "FlappyConfig.h"
#import "MJExtension.h"
#import "FlappyData.h"
#import "FlappyIM.h"
#import "Aes128.h"
#import "RSATool.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>



@interface FlappySocket()

//读取的数据
@property (nonatomic,strong) NSMutableData*  receiveData;
//读取的数据
@property (nonatomic,strong) NSMutableArray*  updatingArray;
//心跳计时
@property (nonatomic, strong) dispatch_source_t heartBeatTimer;
//当前socket的秘钥
@property (nonatomic,copy) NSString*  channelSecret;

@end


@implementation FlappySocket


//socket通信
static  GCDAsyncSocket*  _instanceSocket;


//初始化
-(instancetype)initWithSuccess:(FlappySuccess)success
                    andFailure:(FlappyFailureWrap*)failure
                       andDead:(FlappyDead)dead{
    self=[super init];
    if(self!=nil){
        self.isActive=false;
        self.receiveData=[[NSMutableData alloc]init];
        self.updatingArray =[[NSMutableArray alloc]init];
        self.channelSecret = [FlappyStringTool RandomString:16];
        self.loginSuccess=success;
        self.loginFailure=failure;
        self.dead=dead;
    }
    return self;
}


//socket上线
-(void)connectSocket:(NSString*)serverAddress
            withPort:(NSString*)serverPort
            withUser:(ChatUser*)user{
    
    @synchronized (FlappySocket.class) {
        @try {
            //建立长连接
            if(_instanceSocket==nil){
                _instanceSocket=[[GCDAsyncSocket alloc] init];
            }
            self.socket=_instanceSocket;
            self.socket.delegateQueue=dispatch_get_main_queue();
            self.socket.delegate= self;
            [FlappySender shareInstance].flappySocket=self;
            
            //错误
            NSError* error=nil;
            [self.socket connectToHost:serverAddress
                                onPort:serverPort.integerValue
                           withTimeout:20
                                 error:&error];
            //失败
            if(error!=nil){
                NSLog(@"FlappyIM:%@",error.description);
                [self.loginFailure completeBlock:error andCode:RESULT_NETERROR];
                self.loginFailure=nil;
                self.loginSuccess=nil;
            }
            //成功
            else{
                self.user=user;
            }
        } @catch (NSException *exception) {
            //打印错误日志
            NSLog(@"FlappyIM:%@",exception.description);
        }
    }
}

//socket下线
-(void)offline:(Boolean)regular{
    //加上锁，处理下线
    @synchronized (FlappySocket.class) {
        @try {
            //非active状态
            self.isActive=false;
            
            //主动断开连接
            if(self.socket!=nil){
                [self.socket disconnect];
                self.socket.delegate= nil;
                self.socket=nil;
            }
            
            //登录失败
            if(self.loginFailure!=nil){
                [self.loginFailure completeBlock:[NSError errorWithDomain:@"Socket closed by a new login thread"
                                                                     code:0
                                                                 userInfo:nil] andCode:RESULT_NETERROR];
                self.loginFailure=nil;
                self.loginSuccess=nil;
            }
            
            //心跳停止
            [self stopHeartBeat];
            
            //正常退出，非正常退出的回调不执行
            if(self.dead!=nil){
                if(!regular){
                    self.dead();
                }else{
                    self.dead=nil;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@",exception.description);
        }
    }
}


#pragma GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    
}
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    
}
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
    
}
- (void)socketDidSecure:(GCDAsyncSocket *)sock{
    
}
- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler{
    
}
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    return 3;
}
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    
    return 3;
}

///连接成功
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    //发送登录信息
    [self sendLoginRequest];
    //开启心跳
    [self startHeartBeat];
}


/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    @try {
        //数据
        [self.receiveData appendData:data];
        
        //读取data的头部占用字节和从头部读取内容长度
        int32_t headL = 0;
        int32_t contentL = [self getContentLength:self.receiveData
                                   withHeadLength:&headL];
        //数据获取并不完成的情况
        if (contentL < 1){
            [sock readDataWithTimeout:-1 tag:0];
            return;
        }
        
        //拆包情况下：继续接收下一条消息，直至接收完这条消息所有的拆包，再解析
        if (headL + contentL > self.receiveData.length){
            [sock readDataWithTimeout:-1 tag:0];
            return;
        }
        
        //当receiveData长度不小于第一条消息内容长度时，开始解析receiveData
        [self parseContentDataWithHeadLength:headL withContentLength:contentL];
        
        //修改
        [sock readDataWithTimeout:-1 tag:tag];
        
    } @catch (NSException *exception) {
        NSLog(@"%@",exception.description);
    }
    
}

//解析二进制数据：NSData --> 自定义模型对象
- (void)parseContentDataWithHeadLength:(int32_t)headL withContentLength:(int32_t)contentL{
    
    @try {
        //本次解析data的范围
        NSRange range = NSMakeRange(0, headL + contentL);
        
        //本次解析的data
        NSData *data = [self.receiveData subdataWithRange:range];
        
        //接收到的所有数据转换为数据流
        GPBCodedInputStream *inputStream = [GPBCodedInputStream streamWithData:data];
        //错误
        NSError *error;
        //解析数据
        FlappyResponse *obj = [FlappyResponse parseDelimitedFromCodedInputStream:inputStream
                                                               extensionRegistry:nil
                                                                           error:&error];
        //如果正确解析
        if (!error){
            //保存解析正确的模型对象
            if (obj){
                [self handleReceivedMessage:obj];
            }
            //移除已经解析过的data
            [self.receiveData replaceBytesInRange:range
                                        withBytes:NULL
                                           length:0];
        }
        //且没有更多数据
        if (self.receiveData.length < 1)
            return;
        //实际包不足解析，继续接收下一个包
        headL = 0;
        contentL = [self getContentLength:self.receiveData
                           withHeadLength:&headL];
        if (headL + contentL > self.receiveData.length) {
            return;
        }
        //对于粘包情况下被合并的多条消息，循环递归直至解析完所有消息
        [self parseContentDataWithHeadLength:headL
                           withContentLength:contentL];
    } @catch (NSException *exception) {
        
        NSLog(@"%@",exception.description);
    }
}

/** 获取data数据的内容长度和头部长度: index --> 头部占用长度 (头部占用长度1-4个字节) */
- (int32_t)getContentLength:(NSData *)data withHeadLength:(int32_t *)index {
    int32_t result = 0;
    int32_t shift = 0;
    int8_t tmp;
    do {
        //数据不完整
        if (*index >= data.length) {
            return -1;
        }
        tmp = ((int8_t *)data.bytes)[*index];
        result |= (tmp & 0x7f) << shift;
        shift += 7;
        
        (*index)++;
    } while (tmp < 0 && shift < 32);
    // 继续读取下一个字节，直到找到一个正数或者读取了32位
    if (tmp < 0) {
        // 如果最后一个字节是负数，则表示数据格式错误
        return -1;
    }
    return result;
}

//断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    //非正常d退出
    [self offline:false];
    [[FlappySender shareInstance] handleSendFailureAllCallback];
}


#pragma mark - private methods  辅助方法


//发送登录信息
-(void)sendLoginRequest{
    @try {
        //组装登录数据
        ReqLogin* info=[[ReqLogin alloc]init];
        //用户ID
        info.userId=self.user.userId;
        //类型
        info.devicePlat=[[FlappyData shareInstance] getDevicePlat];
        //推送ID
        info.deviceId=[[FlappyData shareInstance] getDeviceId];
        //设置秘钥
        NSString* rsaKey = [[FlappyData shareInstance] getRsaPublicKey];
        if(rsaKey!=nil && rsaKey.length!=0){
            info.secret = [RSATool encryptWithPublicKey:rsaKey
                                               withData:self.channelSecret];
        }
        //没有设置就用当前的
        else{
            info.secret = self.channelSecret;
        }
        //登录信息
        if([[FlappyData shareInstance] getUser]!=nil){
            info.latest=[[FlappyData shareInstance] getUser].latest;
        }
        //连接到服务器开始请求登录
        FlappyRequest* request=[[FlappyRequest alloc]init];
        //登录请求
        request.type=REQ_LOGIN;
        //登录信息
        request.login=info;
        //请求数据，已经GPBComputeRawVarint32SizeForInteger
        NSData* reqData=[request delimitedData];
        //写入请求数据
        [self.socket writeData:reqData withTimeout:-1 tag:0];
        //开启数据读取
        [self.socket readDataWithTimeout:-1 tag:0];
    } @catch (NSException *exception) {
        NSLog(@"FlappyIM:%@",exception.description);
    }
}


//发送消息
-(void)sendMessage:(ChatMessage*) chatMsg{
    @try {
        //发送消息轻轻
        FlappyRequest* request=[[FlappyRequest alloc]init];
        
        //消息请求
        request.type=REQ_MSG;
        
        //消息内容
        request.msg=[FlappyBaseSession changeToMessage:chatMsg];
        
        
        //秘钥加密
        request.msg.messageContent = [Aes128 AES128Encrypt:chatMsg.messageContent
                                                   withKey:chatMsg.messageSecret];
        
        //渠道Channel秘钥加密消息秘钥
        request.msg.messageSecret = [Aes128 AES128Encrypt:chatMsg.messageSecret
                                                  withKey:_channelSecret];
        
        
        //请求数据，已经GPBComputeRawVarint32SizeForInteger
        NSData* reqData=[request delimitedData];
        //写入时间
        long time=(long)[NSDate date].timeIntervalSince1970*1000;
        //写入请求数据
        [self.socket writeData:reqData withTimeout:-1 tag:time];
    } @catch (NSException *exception) {
        //失败消息
        [[FlappySender shareInstance] handleSendFailureCallback:chatMsg];
    }
}


//处理解析出来的信息,新消息过来了
- (void)handleReceivedMessage:(FlappyResponse *)respones{
    //返回登录消息
    if(respones.type==RES_LOGIN)
    {
        [self receiveLogin: respones];
    }
    //接收到新的消息
    else if(respones.type==RES_MSG){
        [self receiveMessage: respones];
    }
    //会话更新
    else if(respones.type==RES_UPDATE){
        [self receiveUpdate: respones];
    }
}


//检查是否有会话需要更新
-(void)checkSystemMessageFunction{
    
    //用户数据
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    
    //获取未处理的系统消息
    NSMutableArray* array= [[FlappyDataBase shareInstance] getNotActionSystemMessage];
    
    //数据信息拆分
    NSMutableArray* actionUpdateSessionAll = [[NSMutableArray alloc] init];
    NSMutableArray* actionUpdateSessionMember = [[NSMutableArray alloc] init];
    NSMutableArray* actionUpdateSessionMemberDel = [[NSMutableArray alloc] init];
    
    //获取需要更新的会话
    for(int s=0;s<array.count;s++){
        //全量更新
        ChatMessage* message=[array objectAtIndex:s];
        //消息
        ChatSystem* chatSystem=[message getChatSystem];
        //消息
        if(chatSystem.sysAction ==SYSTEM_MSG_NOTHING ){
            message.messageReadState = 1;
            [[FlappyDataBase shareInstance] insertMessage:message];
        }
        //会话
        if(chatSystem.sysAction ==SYSTEM_MSG_UPDATE_SESSION ){
            [actionUpdateSessionAll addObject:message];
        }
        //更新用户信息
        if(chatSystem.sysAction ==SYSTEM_MSG_UPDATE_MEMBER ){
            [actionUpdateSessionMember addObject:message];
        }
        //用户加入是自己也全量更新
        if(chatSystem.sysAction ==SYSTEM_MSG_ADD_MEMBER ){
            NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[message getChatSystem].sysData];
            ChatSessionMember* member = [ChatSessionMember mj_objectWithKeyValues:dic];
            if([member.userId isEqualToString: user.userId]){
                [actionUpdateSessionAll addObject:message];
            }else{
                [actionUpdateSessionMember addObject:message];
            }
        }
        //用户删除是自己删除会话
        if(chatSystem.sysAction ==SYSTEM_MSG_DELETE_MEMBER ){
            NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[message getChatSystem].sysData];
            ChatSessionMember* member = [ChatSessionMember mj_objectWithKeyValues:dic];
            if([member.userId isEqualToString: user.userId]){
                [actionUpdateSessionMemberDel addObject:message];
            }else{
                [actionUpdateSessionMember addObject:message];
            }
        }
    }
    if(actionUpdateSessionAll.count>0){
        [self updateSessionAll:actionUpdateSessionAll];
    }
    if(actionUpdateSessionMember.count>0){
        [self updateSessionMemberUpdate:actionUpdateSessionMember];
    }
    if(actionUpdateSessionMemberDel.count>0){
        [self updateSessionDeleteSelf:actionUpdateSessionMemberDel];
    }
}

//登录成功后发送已经被缓存的消息数据
-(void)checkCachedMessagesToSend{
    __weak typeof(self) safeSelf=self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary* dic=[FlappySender shareInstance].sendingMessages;
        NSMutableArray* messageList=[[NSMutableArray alloc]init];
        NSArray* array=dic.allKeys;
        for(int s=0;s<array.count;s++){
            ChatMessage* msg=[dic objectForKey:array[s]];
            if(msg!=nil){
                [messageList addObject: msg];
            }
        }
        for(int s=0;s<messageList.count;s++){
            [safeSelf sendMessage:messageList[s]];
        }
    });
}


//接收完成登录消息
-(void)receiveLogin:(FlappyResponse *)respones{
    
    //登录成功后保存推送类型，保存用户所有的会话列表
    @try {
        //当前在线了
        self.isActive=true;
        
        //用户已经登录过了
        self.user.login=true;
        
        //保存用户登录数据
        [[FlappyData shareInstance] saveUser:self.user];
        
        //转换消息
        NSMutableArray* array=respones.msgArray;
        NSMutableArray* receiveMessageList=[[NSMutableArray alloc]init];
        for(long s=0;s<array.count;s++){
            Message* message=[array objectAtIndex:s];
            
            //消息解析
            ChatMessage* chatMsg=[ChatMessage mj_objectWithKeyValues:[message mj_keyValues]];
            
            //秘钥解析
            if(chatMsg.messageSecret!=nil && chatMsg.messageSecret.length!=0){
                chatMsg.messageSecret = [Aes128 AES128Decrypt:chatMsg.messageSecret
                                                      withKey:self.channelSecret];
            }
            
            //内容解析
            if(chatMsg.messageSecret!=nil && chatMsg.messageSecret.length!=0 &&
               chatMsg.messageContent!=nil && chatMsg.messageContent.length!=0){
                chatMsg.messageContent = [Aes128 AES128Decrypt:chatMsg.messageContent
                                                       withKey:chatMsg.messageSecret];
            }
            
            
            [receiveMessageList addObject:chatMsg];
        }
        
        //会话插入
        id sessionsData=self.loginData[@"sessions"];
        if(sessionsData!=nil && [sessionsData isKindOfClass:[NSArray class]]){
            NSArray* sessionsArray = sessionsData;
            //修改session
            NSMutableArray* sessions=[[NSMutableArray alloc]init];
            //遍历
            for(int s=0;s<sessionsArray.count;s++){
                NSDictionary* dic=[sessionsArray objectAtIndex:s];
                ChatSessionData* data=[ChatSessionData  mj_objectWithKeyValues:dic];
                [sessions addObject:data];
            }
            //插入会话数据
            [[FlappyDataBase shareInstance] insertSessions:sessions];
            
            //通知会话来了
            [[FlappySender shareInstance] notifySessionReceiveList:sessions];
            
            //如果sessions不为空代表是登录，如果是登录的情况下，所有会话是已经同步的，所以不需要过多的处理
            for(long s=0;s<receiveMessageList.count;s++){
                ChatMessage* chatMsg=[receiveMessageList objectAtIndex:s];
                if(chatMsg.messageType == MSG_TYPE_SYSTEM || chatMsg.messageType == MSG_TYPE_ACTION){
                    chatMsg.messageReadState=1;
                }
            }
        }
        
        //进行排序
        [receiveMessageList sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            ChatMessage* one=obj1;
            ChatMessage* two=obj2;
            if(one.messageTableOffset>two.messageTableOffset){
                return NSOrderedDescending;
            }
            return NSOrderedAscending;
        }];
        
        
        NSMutableSet *sessionIdSet = [[NSMutableSet alloc] init];
        //登录的时候插入的消息必然是新收到的消息
        for(long s=0;s<receiveMessageList.count;s++){
            //获取消息
            ChatMessage* chatMsg=[receiveMessageList objectAtIndex:s];
            //修改消息状态
            [self handleMessageSendArriveState:chatMsg];
            //保存消息
            [[FlappyDataBase shareInstance] insertMessage:chatMsg];
            //通知事件消息
            [[FlappySender shareInstance] handleMessageAction:chatMsg];
            //发送成功
            [[FlappySender shareInstance] handleSendSuccessCallback:chatMsg];
            //会话ID
            [sessionIdSet addObject:chatMsg.messageSessionId];
        }
        
        //session array
        NSMutableArray* sessionArray = [[NSMutableArray alloc] init];
        for(NSString *sessionId in sessionIdSet){
            ChatSessionData* sessionData = [[FlappyDataBase shareInstance] getUserSessionByID:sessionId];
            if(sessionData!=nil){
                [sessionArray addObject:sessionData];
            }
        }
        
        
        //消息列表被接收到
        [[FlappySender shareInstance] notifySessionUpdateList:sessionArray];
        
        
        //消息列表被接收到
        [[FlappySender shareInstance] notifyMessageReceiveList:receiveMessageList];
        
        
        //消息送达的回执消息
        if(receiveMessageList.count>0){
            [self messageArrivedReceipt:receiveMessageList.lastObject];
        }
        
        //登录成功
        if(self.loginSuccess!=nil){
            self.loginSuccess(self.loginData);
        }
        self.loginSuccess=nil;
        self.loginFailure=nil;
        self.loginData=nil;
        
        //检查session 是否需要更新
        [self checkSystemMessageFunction];
        
        //检查之前是否有消息再消息栈中而且没有发送成功
        [self checkCachedMessagesToSend];
        
    } @catch (NSException *exception) {
        NSLog(@"FlappyIM:%@",exception.description);
    }
}


//接收到消息
-(void)receiveMessage:(FlappyResponse *)respones{
    //消息信息
    NSMutableArray* array=respones.msgArray;
    NSMutableArray* receiveMessageList=[[NSMutableArray alloc] init];
    
    //遍历
    for(int s=0;s<array.count;s++){
        Message* message=[array objectAtIndex:s];
        //转换一下
        ChatMessage* chatMsg=[ChatMessage mj_objectWithKeyValues:[message mj_keyValues]];
        
        //秘钥解析
        if(chatMsg.messageSecret!=nil && chatMsg.messageSecret.length!=0){
            chatMsg.messageSecret = [Aes128 AES128Decrypt:chatMsg.messageSecret
                                                  withKey:self.channelSecret];
        }
        
        //内容解析
        if(chatMsg.messageSecret!=nil && chatMsg.messageSecret.length!=0 &&
           chatMsg.messageContent!=nil && chatMsg.messageContent.length!=0){
            chatMsg.messageContent = [Aes128 AES128Decrypt:chatMsg.messageContent
                                                   withKey:chatMsg.messageSecret];
        }
        
        //修改消息状态
        [self handleMessageSendArriveState:chatMsg];
        //添加数据
        [[FlappyDataBase shareInstance] insertMessage:chatMsg];
        //通知事件消息
        [[FlappySender shareInstance] handleMessageAction:chatMsg];
        //消息发送成功
        [[FlappySender shareInstance] handleSendSuccessCallback:chatMsg];
        //通知接收到消息
        [[FlappySender shareInstance] notifyMessageReceive:chatMsg];
        //会话更新
        ChatSessionData* sessionData = [[FlappyDataBase shareInstance] getUserSessionByID:chatMsg.messageSessionId];
        //通知接收到消息
        [[FlappySender shareInstance] notifySessionUpdate:sessionData];
        //消息接收到
        [receiveMessageList addObject:chatMsg];
    }
    
    //消息送达的回执消息
    if(receiveMessageList.count>0){
        [self messageArrivedReceipt:receiveMessageList.lastObject];
    }
    
    [self checkSystemMessageFunction];
}

//接收更新
-(void)receiveUpdate:(FlappyResponse *)respones{
    //移除
    if(respones.update!=nil && respones.update.updateId!=nil){
        [self.updatingArray removeObject:respones.update.updateId];
    }
    //Session Array
    NSMutableArray* sessions=respones.sessionsArray;
    //返回的session
    if(sessions!=nil&&sessions.count>0){
        //遍历
        for(int x=0;x<sessions.count;x++){
            //获取会话
            Session* memSession=[sessions objectAtIndex:x];
            //创建
            ChatSessionData* data=[ChatSessionData mj_objectWithKeyValues:[memSession mj_keyValues]];
            //插入消息
            [[FlappyDataBase shareInstance] insertSession:data];
            //会话更新了
            [[FlappySender shareInstance] notifySessionReceive:data];
            //消息列表
            NSMutableArray* messages=[[FlappyDataBase shareInstance] getNotActionSystemMessageBySessionId:data.sessionId];
            //遍历更新
            for(int w=0;w<messages.count;w++){
                //消息
                ChatMessage* msg=[messages objectAtIndex:w];
                //判断会话时间戳
                if(data.sessionStamp>=[msg getChatSystem].sysTime.longLongValue){
                    //更新消息设置
                    msg.messageReadState=1;
                    //插入消息
                    [[FlappyDataBase shareInstance] insertMessage:msg];
                }
            }
        }
    }
}


//消息收到状态
-(void)handleMessageSendArriveState:(ChatMessage*)message{
    //获取之前的消息ID
    ChatMessage* former=[[FlappyDataBase shareInstance] getMessageById:message.messageId];
    
    //更新发送或者接收的状态
    ChatUser* user=[[FlappyData shareInstance]getUser];
    if([user.userId isEqualToString:message.messageSendId]){
        message.messageSendState=SEND_STATE_SENDED;
    }
    else{
        message.messageSendState=SEND_STATE_REACHED;
    }
    if(former!=nil){
        message.messageReadState=former.messageReadState;
    }
}


//发送已经到达的消息
-(void)messageArrivedReceipt:(ChatMessage*)message{
    
    //设置用户
    ChatUser* user=[[FlappyData shareInstance] getUser];
    if(user.latest==nil){
        user.latest  = [NSString stringWithFormat:@"%ld",(long)message.messageTableOffset];
    }else{
        long formerL = user.latest.longLongValue;
        long newerL  = message.messageTableOffset;
        user.latest  = [NSString stringWithFormat:@"%ld",(formerL>newerL ? formerL:newerL )];
    }
    [[FlappyData shareInstance]saveUser:user];
    
    //如果不为空
    if(user!=nil&&![user.userId isEqualToString:message.messageSendId]){
        
        //连接到服务器开始请求登录
        FlappyRequest* request=[[FlappyRequest alloc]init];
        
        //创建回执请求
        request.type=REQ_RECEIPT;
        ReqReceipt* reciept=[[ReqReceipt alloc]init];
        reciept.receiptType=RECEIPT_MSG_ARRIVE;
        reciept.receiptId=[NSString stringWithFormat:@"%ld",(long)message.messageTableOffset];
        
        @try {
            //设置请求的回执数据
            request.receipt=reciept;
            NSData* reqData=[request delimitedData];
            [self.socket writeData:reqData withTimeout:-1 tag:0];
        } @catch (NSException *exception) {
            NSLog(@"%@",exception.description);
        }
    }
}


//会话所有数据更新
-(void)updateSessionAll:(NSMutableArray*)array{
    //开始写数据了
    for(ChatMessage* msg in array){
        //UpdateID
        NSString* updateId = msg.messageSessionId;
        if([self.updatingArray containsObject:updateId]){
            continue;;
        }
        [self.updatingArray addObject:updateId];
        //创建update
        ReqUpdate* reqUpdate=[[ReqUpdate alloc]init];
        //ID
        reqUpdate.updateId = updateId;
        //更新类型
        reqUpdate.updateType=UPDATE_SESSION_ALL;
        //更新请求
        FlappyRequest* req=[[FlappyRequest alloc]init];
        //更新内容
        req.update=reqUpdate;
        //请求更新
        req.type=REQ_UPDATE;
        //请求数据，已经GPBComputeRawVarint32SizeForInteger
        NSData* reqData=[req delimitedData];
        //写入请求数据
        @try {
            [self.socket writeData:reqData withTimeout:-1 tag:0];
        } @catch (NSException *exception) {
            NSLog(@"%@",exception.description);
        }
    }
}

//会话更新用户数据
-(void)updateSessionMemberUpdate:(NSMutableArray*)array{
    
    //开始写数据了
    for(ChatMessage* msg in array){
        //获取更新的数据
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[msg getChatSystem].sysData];
        ChatSessionMember* member = [ChatSessionMember mj_objectWithKeyValues:dic];
        [[FlappyDataBase shareInstance] insertSessionMember:member];
        
        //设置消息已读，不再继续处理
        msg.messageReadState = 1;
        [[FlappyDataBase shareInstance] updateMessage:msg];
        
        //会话用户更新
        ChatSessionData* session = [[FlappyDataBase shareInstance] getUserSessionByID:msg.messageSessionId];
        [[FlappySender shareInstance] notifySessionReceive:session];
    }
}

//会话更新用户删除
-(void)updateSessionDeleteSelf:(NSMutableArray*)array{
    
    //开始写数据了
    for(ChatMessage* msg in array){
        //获取更新的数据
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[msg getChatSystem].sysData];
        ChatSessionMember* member = [ChatSessionMember mj_objectWithKeyValues:dic];
        [[FlappyDataBase shareInstance] insertSessionMember:member];
        
        //设置消息已读，不再继续处理
        msg.messageReadState = 1;
        [[FlappyDataBase shareInstance] updateMessage:msg];
        
        //获取会话信息
        ChatSessionData* session = [[FlappyDataBase shareInstance] getUserSessionByID:msg.messageSessionId];
        session.isDelete = 1;
        
        //删除用户会话
        [[FlappyDataBase shareInstance] deleteUserSession:msg.messageSessionId];
        [[FlappySender shareInstance] notifySessionDelete:session];
    }
}



#pragma heart beat  心跳
#pragma heart beat  心跳

//开启心跳
- (void)startHeartBeat {
    if (self.heartBeatTimer) {
        dispatch_source_cancel(self.heartBeatTimer);
    }
    
    self.heartBeatTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.heartBeatTimer, DISPATCH_TIME_NOW, [FlappyApiConfig shareInstance].heartInterval * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.heartBeatTimer, ^{
        [self sendHeartBeat];
    });
    dispatch_resume(self.heartBeatTimer);
}

//发送心跳
- (void)sendHeartBeat {
    if (self.socket) {
        @try {
            FlappyRequest *request = [[FlappyRequest alloc] init];
            request.type = REQ_PING;
            NSData *reqData = [request delimitedData];
            [self.socket writeData:reqData withTimeout:-1 tag:0];
            NSLog(@"heart beat");
        } @catch (NSException *exception) {
            NSLog(@"%@", exception.description);
        }
    }
}

//停止心跳
- (void)stopHeartBeat {
    if (self.heartBeatTimer) {
        dispatch_source_cancel(self.heartBeatTimer);
        self.heartBeatTimer = nil;
    }
}



@end
