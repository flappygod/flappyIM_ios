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
#import "FlappySender.h"
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
@property (nonatomic,strong) NSTimer*  connectTimer;
//当前socket的秘钥
@property (nonatomic,copy) NSString*  secret;

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
        self.secret = [FlappyStringTool RandomString:16];
        self.loginSuccess=success;
        self.loginFailure=failure;
        self.dead=dead;
    }
    return self;
}


//建立长连接
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




#pragma GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    @try {
        //组装登录数据
        ReqLogin* info=[[ReqLogin alloc]init];
        //类型
        info.device=DEVICE_TYPE;
        //用户ID
        info.userId=self.user.userId;
        //推送ID
        info.pushId=[[FlappyData shareInstance] getPush];
        //设置秘钥
        NSString* rsaKey = [[FlappyData shareInstance] getRsaKey];
        if(rsaKey!=nil && rsaKey.length!=0){
            info.secret = [RSATool encryptWithPublicKey:rsaKey
                                               withData:self.secret];
        }
        //没有设置就用当前的
        else{
            info.secret = self.secret;
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
    
    //停止之前的
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(startHeart:)
                                               object:nil];
    //开启心跳线程
    [self performSelectorOnMainThread:@selector(startHeart:)
                           withObject:nil
                        waitUntilDone:false];
    
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
        int32_t contentL = [FlappyApiRequest getContentLength:self.receiveData
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
                [self msgRecieved:obj];
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
        contentL = [FlappyApiRequest getContentLength:self.receiveData
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


- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}

- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    
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

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    //非正常d退出
    [self offline:false];
    //退出了
    __weak typeof(self) safeSelf=self;
    //通知所有的消息错误
    dispatch_async(dispatch_get_main_queue(), ^{
        //错误
        if([FlappySender shareInstance].sendingMessages==nil||[FlappySender shareInstance].sendingMessages.count==0){
            return;
        }
        NSMutableDictionary* dic=[FlappySender shareInstance].sendingMessages;
        NSArray* array=dic.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* messageid=[array objectAtIndex:s];
            ChatMessage* chatMsg=[[FlappySender shareInstance].sendingMessages objectForKey:messageid];
            if(chatMsg!=nil){
                [safeSelf notifyMessageFailure:chatMsg];
                [[FlappySender shareInstance] failureCallback:chatMsg];
            }
        }
    });
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock{
    
}

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler{
    
}

#pragma readData
#pragma mark - private methods  辅助方法

//主动下线
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
            [self stopHeart];
            
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
        if(chatMsg.messageSecret!=nil && chatMsg.messageSecret.length!=0){
            request.msg.messageSecret = [Aes128 AES128Encrypt:chatMsg.messageSecret
                                                      withKey:self.secret];
        }
        
        //请求数据，已经GPBComputeRawVarint32SizeForInteger
        NSData* reqData=[request delimitedData];
        //写入时间
        long time=(long)[NSDate date].timeIntervalSince1970*1000;
        //写入请求数据
        [self.socket writeData:reqData withTimeout:-1 tag:time];
    } @catch (NSException *exception) {
        //通知所有的消息错误
        __weak typeof(self) safeSelf=self;
        dispatch_async(dispatch_get_main_queue(), ^{
            ChatMessage* message=[[FlappySender shareInstance].sendingMessages
                                  objectForKey:chatMsg.messageId];
            [safeSelf notifyMessageFailure:message];
            [[FlappySender shareInstance] failureCallback:message];
        });
    }
}


//处理解析出来的信息,新消息过来了
- (void)msgRecieved:(FlappyResponse *)respones{
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

//接收完成登录消息
-(void)receiveLogin:(FlappyResponse *)respones{
    //当前在线了
    self.isActive=true;
    //用户已经登录过了
    self.user.login=true;
    //保存用户登录数据
    [[FlappyData shareInstance] saveUser:self.user];
    
    //登录成功后保存推送类型，保存用户所有的会话列表
    @try {
        
        if(self.loginData[@"sessions"]!=nil && self.loginData[@"sessions"]!=[NSNull null]){
            //修改
            NSArray* array=self.loginData[@"sessions"];
            //修改session
            NSMutableArray* sessions=[[NSMutableArray alloc]init];
            //遍历
            for(int s=0;s<array.count;s++){
                //数据字典
                NSDictionary* dic=[array objectAtIndex:s];
                //数据
                SessionData* data=[SessionData  mj_objectWithKeyValues:dic];
                //添加
                [sessions addObject:data];
                //会话更新了
                [self notifySession:data];
            }
            //插入会话数据
            [[FlappyDataBase shareInstance] insertSessions:sessions];
        }
    } @catch (NSException *exception) {
        NSLog(@"FlappyIM:%@",exception.description);
    }
    
    
    //消息信息
    @try {
        NSMutableArray* array=respones.msgArray;
        //转换
        NSMutableArray* messageList=[[NSMutableArray alloc]init];
        for(long s=0;s<array.count;s++){
            //获取消息
            Message* message=[array objectAtIndex:s];
            //转换消息
            ChatMessage* chatMsg=[ChatMessage mj_objectWithKeyValues:[message mj_keyValues]];
            //解密秘钥
            if(chatMsg.messageSecret!=nil && chatMsg.messageSecret.length!=0){
                chatMsg.messageSecret = [Aes128 AES128Decrypt:chatMsg.messageSecret
                                                      withKey:self.secret];
            }
            //进行添加
            [messageList addObject:chatMsg];
        }
        //进行排序
        [messageList sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            ChatMessage* one=obj1;
            ChatMessage* two=obj2;
            if(one.messageTableOffset>two.messageTableOffset){
                return NSOrderedDescending;
            }
            return NSOrderedAscending;
        }];
        //转换
        for(long s=0;s<messageList.count;s++){
            //获取消息
            ChatMessage* chatMsg=[messageList objectAtIndex:s];
            //获取之前的消息ID
            ChatMessage* former=[[FlappyDataBase shareInstance]getMessageByID:chatMsg.messageId
                                                                showActionMsg:true];
            //修改消息状态
            [self messageArrivedState:chatMsg andFormer:former];
            //保存消息
            [[FlappyDataBase shareInstance] insertMessage:chatMsg];
            //发送成功
            [self messageSendSuccess:chatMsg];
            //通知接收到消息
            [self notifyMessageReceive:chatMsg andFormer:former];
            //通知事件消息
            [self notifyMessageAction:chatMsg];
            
            //最后一条消息
            if(s==(messageList.count-1)){
                [self messageArrivedReceipt:chatMsg andFormer:former];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"FlappyIM:%@",exception.description);
    }
    
    //登录成功
    if(self.loginSuccess!=nil){
        self.loginSuccess(self.loginData);
    }
    self.loginSuccess=nil;
    self.loginFailure=nil;
    self.loginData=nil;
    
    //检查session 是否需要更新
    [self checkSessionNeedUpdate];
    
    //检查之前是否有消息再消息栈中而且没有发送成功
    [self checkFormerMessagesToSend];
}

//接收到消息
-(void)receiveMessage:(FlappyResponse *)respones{
    //消息信息
    NSMutableArray* array=respones.msgArray;
    for(int s=0;s<array.count;s++){
        Message* message=[array objectAtIndex:s];
        //转换一下
        ChatMessage* chatMsg=[ChatMessage mj_objectWithKeyValues:[message mj_keyValues]];
        //解密秘钥
        if(chatMsg.messageSecret!=nil && chatMsg.messageSecret.length!=0){
            chatMsg.messageSecret = [Aes128 AES128Decrypt:chatMsg.messageSecret
                                                  withKey:self.secret];
        }
        //获取之前的消息ID
        ChatMessage* former=[[FlappyDataBase shareInstance]getMessageByID:chatMsg.messageId showActionMsg:true];
        //修改消息状态
        [self messageArrivedState:chatMsg andFormer:former];
        //添加数据
        [[FlappyDataBase shareInstance] insertMessage:chatMsg];
        //消息发送成功
        [self messageSendSuccess:chatMsg];
        //通知接收到消息
        [self notifyMessageReceive:chatMsg andFormer:former];
        //消息接收到
        [self messageArrivedReceipt:chatMsg andFormer:former];
        //通知事件消息
        [self notifyMessageAction:chatMsg];
    }
    [self checkSessionNeedUpdate];
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
            SessionData* data=[SessionData mj_objectWithKeyValues:[memSession mj_keyValues]];
            //插入消息
            [[FlappyDataBase shareInstance] insertSession:data];
            //会话更新了
            [self notifySession:data];
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

//信息发送成功
-(void)messageSendSuccess:(ChatMessage*)message{
    //在主线程之中执行
    dispatch_async(dispatch_get_main_queue(), ^{
        [[FlappySender shareInstance] successCallback:message];
    });
}

//消息收到状态
-(void)messageArrivedState:(ChatMessage*)message andFormer:(ChatMessage*)former{
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
-(void)messageArrivedReceipt:(ChatMessage*)message
                   andFormer:(ChatMessage*)former{
    
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
    //如果再后台
    if([FlappyIM shareInstance].isForground){
        NSLog(@"当前处于UNMutableNotificationContent,收到信息");
        //存活状态才返回信息
        ChatUser* user=[[FlappyData shareInstance]getUser];
        //如果不为空
        if(user!=nil&&![user.userId isEqualToString:message.messageSendId] && former == nil){
            
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
}

//会话
-(void)notifySession:(SessionData*)session{
    //在主线程之中执行
    dispatch_async(dispatch_get_main_queue(), ^{
        //新消息
        NSArray* array=[FlappyIM shareInstance].sessionListeners;
        //数量
        for(int s=0;s<array.count;s++){
            SessionListener listener=[array objectAtIndex:s];
            listener(session);
        }
    });
}


//通知有新的消息
-(void)notifyMessageReceive:(ChatMessage*)message
                  andFormer:(ChatMessage*)former{
    if(message==nil){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            if([str isEqualToString:GlobalKey] || [str isEqualToString:message.messageSession]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    if(former==nil){
                        [listener onReceive:message];
                    }else{
                        [listener onUpdate:message];
                    }
                }
            }
        }
    });
}

//消息已读回执和删除回执,对方的阅读消息存在的时候才会执行
-(void)notifyMessageAction:(ChatMessage*)message{
    if(message==nil){
        return;
    }
    if(message.messageType == MSG_TYPE_ACTION){
        [[FlappyDataBase shareInstance] handleActionMessageUpdate:message];
        ChatAction* chatAction = [message getChatAction];
        switch(chatAction.actionType){
            case ACTION_TYPE_READ:{
                ChatUser* user=[[FlappyData shareInstance] getUser];
                //自己读的
                if([user.userId isEqualToString:chatAction.actionIds[0]]){
                    [self notifyMessageSelfRead:chatAction.actionIds[1]
                                    andReaderId:chatAction.actionIds[0]
                               andTableSequecne:chatAction.actionIds[2]];
                }
                //其他人读的
                else{
                    [self notifyMessageOtherRead:chatAction.actionIds[1]
                                     andReaderId:chatAction.actionIds[0]
                                andTableSequecne:chatAction.actionIds[2]];
                }
                break;
            }
            case ACTION_TYPE_DELETE:{
                [self notifyMessageDelete:chatAction.actionIds[1]
                         andTableSequecne:chatAction.actionIds[2]];
                break;
            }
        }
    }
}

//通知消息失败
-(void)notifyMessageFailure:(ChatMessage*)message{
    if(message==nil){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            //当前会话或者全局
            if([str isEqualToString:GlobalKey] || [str isEqualToString:message.messageSession]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onFailure:message];
                }
            }
        }
    });
}

//通知有新的消息
-(void)notifyMessageOtherRead:(NSString*)sessionId
                  andReaderId:(NSString*)readerId
             andTableSequecne:(NSString*)tableOffset{
    if(sessionId==nil || tableOffset==nil){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            //当前会话或者全局
            if([str isEqualToString:GlobalKey] || [str isEqualToString:sessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onOtherRead:sessionId
                              andReaderId:readerId
                               andSequece:tableOffset];
                }
            }
            
        }
    });
}

//通知有新的消息
-(void)notifyMessageSelfRead:(NSString*)sessionId
                 andReaderId:(NSString*)readerId
            andTableSequecne:(NSString*)tableOffset{
    if(sessionId==nil || tableOffset==nil){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            //当前会话或者全局
            if([str isEqualToString:GlobalKey] || [str isEqualToString:sessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onSelfRead:sessionId
                             andReaderId:readerId
                              andSequece:tableOffset];
                }
            }
            
        }
    });
}

//通知有新的消息
-(void)notifyMessageDelete:(NSString*)sessionId
          andTableSequecne:(NSString*)messageId{
    if(sessionId==nil || messageId==nil){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            //当前会话或者全局
            if([str isEqualToString:GlobalKey] || [str isEqualToString:sessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onDelete:messageId];
                }
            }
        }
    });
}

//检查是否有会话需要更新
-(void)checkSessionNeedUpdate{
    
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
        if([message getChatSystem].sysAction ==SYSTEM_MSG_NOTHING ){
            message.messageReadState = 1;
            [[FlappyDataBase shareInstance] insertMessage:message];
        }
        //会话
        if([message getChatSystem].sysAction ==SYSTEM_MSG_UPDATE_SESSION ){
            [actionUpdateSessionAll addObject:message];
        }
        //更新用户信息
        if([message getChatSystem].sysAction ==SYSTEM_MSG_UPDATE_MEMBER ){
            [actionUpdateSessionMember addObject:message];
        }
        //用户加入是自己也全量更新
        if([message getChatSystem].sysAction ==SYSTEM_MSG_ADD_MEMBER ){
            NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[message getChatSystem].sysData];
            SessionDataMember* member = [SessionDataMember mj_objectWithKeyValues:dic];
            if([member.userId isEqualToString: user.userId]){
                [actionUpdateSessionAll addObject:message];
            }else{
                [actionUpdateSessionMember addObject:message];
            }
        }
        //用户删除是自己删除会话
        if([message getChatSystem].sysAction ==SYSTEM_MSG_DELETE_MEMBER ){
            NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[message getChatSystem].sysData];
            SessionDataMember* member = [SessionDataMember mj_objectWithKeyValues:dic];
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
        [self updateSessionMemberDelete:actionUpdateSessionMemberDel];
    }
}


//会话所有数据更新
-(void)updateSessionAll:(NSMutableArray*)array{
    //开始写数据了
    for(ChatMessage* msg in array){
        //UpdateID
        NSString* updateId = msg.messageSession;
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
        SessionDataMember* member = [SessionDataMember mj_objectWithKeyValues:dic];
        [[FlappyDataBase shareInstance] insertSessionMember:member];
        
        //设置消息已读，不再继续处理
        msg.messageReadState = 1;
        [[FlappyDataBase shareInstance] updateMessage:msg];
        
        //发送会话更新通知
        [self notifySession:[[FlappyDataBase shareInstance] getUserSessionByID:msg.messageSession]];
    }
}

//会话更新用户删除
-(void)updateSessionMemberDelete:(NSMutableArray*)array{
    
    //开始写数据了
    for(ChatMessage* msg in array){
        
        //获取会话信息
        SessionData* session = [[FlappyDataBase shareInstance] getUserSessionByID:msg.messageSession];
        session.isDelete = 1;
        
        //设置消息已读，不再继续处理
        msg.messageReadState = 1;
        [[FlappyDataBase shareInstance] updateMessage:msg];
        
        //删除用户会话
        [[FlappyDataBase shareInstance] deleteUserSession:msg.messageSession];
        
        //发送会话更新通知
        [self notifySession:session];
    }
    
}


//登录成功后发送已经被缓存的消息数据
-(void)checkFormerMessagesToSend{
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



#pragma heart beat  心跳
//开启心跳
-(void)startHeart:(id)sender{
    // 开启心跳
    // 每隔12s像服务器发送心跳包
    // 在longConnectToSocket方法中进行长连接需要向服务器发送的讯息
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:[FlappyApiConfig shareInstance].heartInterval
                                                         target:self
                                                       selector:@selector(heartBeat:)
                                                       userInfo:nil
                                                        repeats:YES];
}

//关闭心跳
-(void)stopHeart{
    //停止
    if(self.connectTimer!=nil){
        [self.connectTimer invalidate];
        self.connectTimer=nil;
    }
}

//长连接的心跳
-(void)heartBeat:(id)sender{
    //心跳消息写入
    if(self.socket!=nil){
        //写入请求数据
        @try {
            //连接到服务器开始请求登录
            FlappyRequest* request=[[FlappyRequest alloc]init];
            //登录请求
            request.type=REQ_PING;
            //请求数据，已经GPBComputeRawVarint32SizeForInteger
            NSData* reqData=[request delimitedData];
            //写入数据
            [self.socket  writeData:reqData withTimeout:-1 tag:0];
        } @catch (NSException *exception) {
            NSLog(@"%@",exception.description);
        }
        NSLog(@"heart beat");
    }
}


@end
