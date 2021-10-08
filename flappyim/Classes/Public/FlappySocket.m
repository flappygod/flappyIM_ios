//
//  SocketConnector.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/17.
//

#import "FlappySocket.h"
#import "FlappySender.h"
#import "MJExtension.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "FlappyConfig.h"
#import "FlappyData.h"
#import "FlappyDataBase.h"
#import "FlappyNetTool.h"
#import "FlappySender.h"
#import "FlappyApiConfig.h"

@interface FlappySocket()

//读取的数据
@property (nonatomic,strong) NSMutableData*  receiveData;
//心跳计时
@property (nonatomic,strong) NSTimer*  connectTimer;

@end


@implementation FlappySocket

//初始化
-(instancetype)initWithSuccess:(FlappySuccess)success
                    andFailure:(FlappyFailureWrap*)failure
                       andDead:(FlappyDead)dead{
    self=[super init];
    if(self!=nil){
        self.isActive=false;
        self.receiveData=[[NSMutableData alloc]init];
        self.updateArray=[[NSMutableArray alloc]init];
        self.success=success;
        self.failure=failure;
        self.dead=dead;
    }
    return self;
}


//建立长连接
-(void)connectSocket:(NSString*)serverAddress
            withPort:(NSString*)serverPort
            withUser:(ChatUser*)user{
    
    
    //建立长连接
    self.socket=[[GCDAsyncSocket alloc] initWithDelegate:self
                                           delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    //保存
    [FlappySender shareInstance].socket=self.socket;
    
    NSError* error=nil;
    
    //连接host
    [self.socket connectToHost:serverAddress
                        onPort:serverPort.integerValue
                   withTimeout:20
                         error:&error];
    
    
    
    //失败
    if(error!=nil){
        NSLog(@"%@",error.description);
        //错误error, RESULT_NETERROR
        [self.failure completeBlock:error andCode:RESULT_NETERROR];
        //错误
        self.failure=nil;
        //连接错误
        self.success=nil;
    }
    //成功
    else{
        //保存用户数据
        self.user=user;
    }
}




#pragma GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    //组装登录数据
    ReqLogin* info=[[ReqLogin alloc]init];
    //类型
    info.device=DEVICE_TYPE;
    //用户ID
    info.userId=self.user.userId;
    //推送ID
    info.pushid=[FlappyIM shareInstance].pushID;
    //登录信息
    if([[FlappyData shareInstance]getUser]!=nil){
        info.latest=[[FlappyData shareInstance]getUser].latest;
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
    //数据
    [self.receiveData appendData:data];
    //读取data的头部占用字节 和 从头部读取内容长度
    //验证结果：数据比较小时头部占用字节为1，数据比较大时头部占用字节为2
    int32_t headL = 0;
    int32_t contentL = [FlappyApiRequest getContentLength:self.receiveData
                                           withHeadLength:&headL];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[FlappySender shareInstance] failureAllCallbacks];
        });
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
    self.isActive=false;
    //正常退出，非正常退出的回调不执行
    if(regular){
        self.dead=nil;
    }
    //主动断开连接
    if(self.socket!=nil){
        [self.socket disconnect];
    }
    //登录失败
    if(self.failure!=nil){
        //失败
        [self.failure completeBlock:[NSError errorWithDomain:@"Socket closed by a new login thread"
                                                        code:0
                                                    userInfo:nil] andCode:RESULT_NETERROR];
        //失败
        self.failure=nil;
        //清空
        self.success=nil;
    }
    //心跳停止
    [self stopHeart];
    //清空socket
    self.socket=nil;
    //非正常退出
    if(self.dead!=nil){
        //非正常退出
        self.dead();
        self.dead=nil;
    }
}

//解析二进制数据：NSData --> 自定义模型对象
- (void)parseContentDataWithHeadLength:(int32_t)headL withContentLength:(int32_t)contentL{
    
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
    if (self.receiveData.length < 1)
        return;
    //对于粘包情况下被合并的多条消息，循环递归直至解析完所有消息
    headL = 0;
    contentL = [FlappyApiRequest getContentLength:self.receiveData
                                   withHeadLength:&headL];
    //实际包不足解析，继续接收下一个包
    if (headL + contentL > self.receiveData.length) return;
    //继续解析下一条
    [self parseContentDataWithHeadLength:headL
                       withContentLength:contentL];
}

//处理解析出来的信息,新消息过来了
- (void)msgRecieved:(FlappyResponse *)respones{
    //返回登录消息
    if(respones.type==RES_LOGIN)
    {
        //当前在线了
        self.isActive=true;
        //用户已经登录过了
        self.user.login=true;
        //保存用户登录数据
        [[FlappyData shareInstance] saveUser:self.user];
        //登录成功
        if(self.success!=nil){
            self.success(self.loginData);
        }
        //登录成功后保存推送类型，保存用户所有的会话列表
        @try {
            //推送类型
            id dataType=self.loginData[@"route"][@"routePushType"];
            //推送类型
            NSInteger type=(long)dataType;
            //保存
            [[FlappyData shareInstance]savePushType:[NSString stringWithFormat:@"%ld",(long)type]];
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
            }
            //插入会话数据
            [[FlappyDataBase shareInstance] insertSessions:sessions];
            
        } @catch (NSException *exception) {
        } @finally {
        }
        //清空回调和数据
        self.success=nil;
        self.failure=nil;
        self.loginData=nil;
        //消息信息
        NSMutableArray* array=respones.msgArray;
        //进行排序
        [array sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            ChatMessage* one=obj1;
            ChatMessage* two=obj2;
            if(one.messageTableSeq>two.messageTableSeq){
                return NSOrderedDescending;
            }
            return NSOrderedAscending;
        }];
        
        NSMutableArray* inserts=[[NSMutableArray alloc]init];
        
        //转换
        for(long s=0;s<array.count;s++){
            Message* message=[array objectAtIndex:s];
            //转换一下
            ChatMessage* chatMsg=[ChatMessage mj_objectWithKeyValues:[message mj_keyValues]];
            //需要更新
            [inserts addObject:chatMsg];
            //修改消息状态
            [self messageArrivedState:chatMsg];
            //获取之前的消息ID
            ChatMessage* former=[[FlappyDataBase shareInstance]getMessageByID:chatMsg.messageId];
            //之前不存在
            if(former==nil){
                [self notifyNewMessage:chatMsg];
            }else{
                //保留是否处理的flag;
                chatMsg.messageReaded=former.messageReaded;
            }
            //消息发送成功
            [self sendMessageSuccess:chatMsg];
        }
        
        //批量插入列表
        [[FlappyDataBase shareInstance] insertMsgs:inserts];
        
        //最后一条的数据保存
        if(array.count>0){
            ChatMessage* last=[array objectAtIndex:array.count-1];
            ChatUser* user=[[FlappyData shareInstance]getUser];
            user.latest=[NSString stringWithFormat:@"%ld",(long)last.messageTableSeq];
            [[FlappyData shareInstance]saveUser:user];
            [self messageArrived:last];
        }
        
        [self checkSessionNeedUpdate];
    }
    //接收到新的消息
    else if(respones.type==RES_MSG){
        //消息信息
        NSMutableArray* array=respones.msgArray;
        for(int s=0;s<array.count;s++){
            Message* message=[array objectAtIndex:s];
            //转换一下
            ChatMessage* chatMsg=[ChatMessage mj_objectWithKeyValues:[message mj_keyValues]];
            //修改消息状态
            [self messageArrivedState:chatMsg];
            //获取之前的消息ID
            ChatMessage* former=[[FlappyDataBase shareInstance]getMessageByID:chatMsg.messageId];
            //之前不存在
            if(former==nil){
                //添加数据
                [[FlappyDataBase shareInstance] insertMsg:chatMsg];
                [self notifyNewMessage:chatMsg];
                [self messageArrived:chatMsg];
            }else{
                //保留是否已经处理的信息
                chatMsg.messageReaded=former.messageReaded;
                [[FlappyDataBase shareInstance] updateMessage:chatMsg];
            }
            [self sendMessageSuccess:chatMsg];
            //更新最近一条的时间
            ChatUser* user=[[FlappyData shareInstance]getUser];
            user.latest=[NSString stringWithFormat:@"%ld",(long)chatMsg.messageTableSeq];
            [[FlappyData shareInstance]saveUser:user];
        }
        [self checkSessionNeedUpdate];
    }
    //会话更新
    else if(respones.type==RES_UPDATE){
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
                NSMutableArray* messages=[[FlappyDataBase shareInstance] getNotActionSystemMessageWithSession:data.sessionId];
                //遍历更新
                for(int w=0;w<messages.count;w++){
                    //消息
                    ChatMessage* msg=[messages objectAtIndex:w];
                    //判断会话时间戳
                    if(data.sessionStamp>=[msg getChatSystem].sysTime.longLongValue){
                        //更新消息设置
                        msg.messageReaded=1;
                        //插入消息
                        [[FlappyDataBase shareInstance] insertMsg:msg];
                    }
                }
                //移除正在更新的
                [self.updateArray removeObject:data.sessionId];
            }
        }
    }
}


//信息发送成功
-(void)sendMessageSuccess:(ChatMessage*)message{
    //在主线程之中执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[FlappySender shareInstance]successCallback:message];
        });
    });
}

//消息收到状态
-(void)messageArrivedState:(ChatMessage*)message{
    ChatUser* user=[[FlappyData shareInstance]getUser];
    if(user!=nil){
        //自己发送的消息，已经发送
        if([user.userId isEqualToString:message.messageSend]){
            message.messageSended=SEND_STATE_SENDED;
        }
        //用户发送的消息已经送达
        else{
            message.messageSended=SEND_STATE_REACHED;
        }
    }
}


//发送已经到达的消息
-(void)messageArrived:(ChatMessage*)message{
    //如果再后台
    if([FlappyIM shareInstance].isActive){
        NSLog(@"当前处于UNMutableNotificationContent,收到信息");
        //存活状态才返回信息
        ChatUser* user=[[FlappyData shareInstance]getUser];
        //如果不为空
        if(user!=nil&&![user.userId isEqualToString:message.messageSend]){
            //连接到服务器开始请求登录
            FlappyRequest* request=[[FlappyRequest alloc]init];
            
            //创建回执请求
            request.type=REQ_RECEIPT;
            ReqReceipt* reciept=[[ReqReceipt alloc]init];
            reciept.receiptType=RECEIPT_MSG_ARRIVE;
            reciept.receiptId=[NSString stringWithFormat:@"%ld",(long)message.messageTableSeq];
            //设置请求的回执数据
            request.receipt=reciept;
            //请求数据，已经GPBComputeRawVarint32SizeForInteger
            NSData* reqData=[request delimitedData];
            //写入数据请求
            [self.socket writeData:reqData withTimeout:-1 tag:0];
        }
    }
}

//会话
-(void)notifySession:(SessionData*)session{
    //在主线程之中执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //新消息
            NSArray* array=[FlappyIM shareInstance].sessinListeners;
            //数量
            for(int s=0;s<array.count;s++){
                SessionListener listener=[array objectAtIndex:s];
                FlappyChatSession* session=[[FlappyChatSession alloc]init];
                listener(session);
            }
        });
    });
}

//通知有新的消息
-(void)notifyNewMessage:(ChatMessage*)message{
    //在主线程之中执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //新消息
            NSArray* array=[FlappyIM shareInstance].msgListeners.allKeys;
            //数量
            for(int s=0;s<array.count;s++){
                NSString* str=[array objectAtIndex:s];
                NSMutableArray* listeners=[[FlappyIM shareInstance].msgListeners objectForKey:str];
                //回调监听的事件
                for(int w=0;w<listeners.count;w++){
                    MessageListener listener=[listeners objectAtIndex:w];
                    listener(message);
                }
            }
        });
    });
}

//检查是否有会话需要更新
-(void)checkSessionNeedUpdate{
    //获取未处理的系统消息
    NSMutableArray* array= [[FlappyDataBase shareInstance] getNotActionSystemMessage];
    //创建
    NSMutableDictionary* dic=[[NSMutableDictionary alloc]init];
    //获取需要更新的会话
    for(int s=0;s<array.count;s++){
        //进行合并
        ChatMessage* message=[array objectAtIndex:s];
        //合并
        NSString* former=dic[message.messageSession];
        //获取数据
        if(former==nil){
            [dic setObject:[message getChatSystem].sysTime
                    forKey:message.messageSession];
        }else{
            //替换数据
            long stamp=former.integerValue;
            long newStamp=[message getChatSystem].sysTime.integerValue;
            if (newStamp > stamp) {
                [dic setObject:[message getChatSystem].sysTime
                        forKey:message.messageSession];
            }
        }
    }
    
    //开始写数据了
    for(NSString* str in dic.allKeys){
        
        if(![self.updateArray containsObject: str]){
            
            [self.updateArray addObject:str];
            
            //创建update
            ReqUpdate* reqUpdate=[[ReqUpdate alloc]init];
            //ID
            reqUpdate.updateId=str;
            //更新类型
            reqUpdate.updateType=UPDATE_SESSION_SGINGLE;
            //更新请求
            FlappyRequest* req=[[FlappyRequest alloc]init];
            //更新内容
            req.update=reqUpdate;
            //请求更新
            req.type=REQ_UPDATE;
            //请求数据，已经GPBComputeRawVarint32SizeForInteger
            NSData* reqData=[req delimitedData];
            //写入请求数据
            [self.socket writeData:reqData withTimeout:-1 tag:0];
        }
        
        
    }
    
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
        //取消timer
        [self.connectTimer invalidate];
        //清空
        self.connectTimer=nil;
    }
}


//长连接的心跳
-(void)heartBeat:(id)sender{
    //心跳消息写入
    if(self.socket!=nil){
        //连接到服务器开始请求登录
        FlappyRequest* request=[[FlappyRequest alloc]init];
        //登录请求
        request.type=REQ_PING;
        //请求数据，已经GPBComputeRawVarint32SizeForInteger
        NSData* reqData=[request delimitedData];
        //写入请求数据
        [self.socket  writeData:reqData withTimeout:-1 tag:0];
        NSLog(@"heart beat");
    }
}


@end
