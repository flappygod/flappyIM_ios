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


-(instancetype)init{
    self=[super init];
    if(self!=nil){
        self.receiveData=[[NSMutableData alloc]init];
    }
    return self;
}


//建立长连接
-(void)connectSocket:(NSString*)serverAddress
            withPort:(NSString*)serverPort
            withUser:(ChatUser*)user
         withSuccess:(FlappySuccess)success
         withFailure:(FlappyFailure)failure
                dead:(FlappyDead)dead{
    
    //保留引用
    self.success=success;
    self.failure=failure;
    
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
        //错误
        self.failure(error, RESULT_NETERROR);
        //错误
        self.failure=nil;
        //连接错误
        self.success=nil;
    }
    //成功
    else{
        //保存用户数据
        self.user=user;
        //socket非正常退出的时候，重新登录
        self.dead = dead;
    }
}




#pragma GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    //组装登录数据
    LoginInfo* info=[[LoginInfo alloc]init];
    //类型
    info.device=DEVICE_TYPE;
    //用户ID
    info.userId=self.user.userId;
    //推送ID
    info.pushid=[FlappyIM shareInstance].pushID;
    
    //连接到服务器开始请求登录
    FlappyRequest* request=[[FlappyRequest alloc]init];
    //登录请求
    request.type=REQ_LOGIN;
    //登录信息
    request.login=info;
    //登录信息
    if([FlappyData getUser]!=nil){
        request.latest=[FlappyData getUser].latest;
    }
    
    //请求数据，已经GPBComputeRawVarint32SizeForInteger
    NSData* reqData=[request delimitedData];
    //写入请求数据
    [self.socket writeData:reqData withTimeout:-1 tag:0];
    //开启数据读取
    [self.socket readDataWithTimeout:-1 tag:0];
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
    //在主线程之中执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[FlappySender shareInstance]successCallback:tag];
            
        });
    });
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
        self.failure([NSError errorWithDomain:@"Socket closed by a new login thread"
                                         code:0
                                     userInfo:nil],
                     RESULT_NETERROR);
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
        //登录成功
        if(self.success!=nil){
            //用户已经登录过了
            self.user.login=true;
            //保存用户登录数据
            [FlappyData saveUser:self.user];
            //登录成功
            self.success(self.loginData);
            //清空回调和数据
            self.success=nil;
            self.failure=nil;
            self.loginData=nil;
        }
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
        //转换
        for(long s=0;s<array.count;s++){
            Message* message=[array objectAtIndex:s];
            //转换一下
            ChatMessage* chatMsg=[ChatMessage mj_objectWithKeyValues:[message mj_keyValues]];
            //接收成功
            chatMsg.messageSended=SEND_STATE_PUSHED;
            //获取之前的消息ID
            ChatMessage* former=[[FlappyDataBase shareInstance]getMessageByID:chatMsg.messageId];
            //之前不存在
            if(former==nil){
                //添加数据
                [[FlappyDataBase shareInstance] insert:chatMsg];
                [self notifyNewMessage:chatMsg];
            }else{
                [[FlappyDataBase shareInstance] updateMessage:chatMsg];
            }
        }
        //最后一条的数据保存
        if(array.count>0){
            ChatMessage* last=[array objectAtIndex:array.count-1];
            ChatUser* user=[FlappyData getUser];
            user.latest=[NSString stringWithFormat:@"%ld",(long)last.messageTableSeq];
            [FlappyData saveUser:user];
            [self sendMessageArrive:last];
        }
        
    }
    //接收到新的消息
    else if(respones.type==RES_MSG){
        //消息信息
        NSMutableArray* array=respones.msgArray;
        for(int s=0;s<array.count;s++){
            Message* message=[array objectAtIndex:s];
            //转换一下
            ChatMessage* chatMsg=[ChatMessage mj_objectWithKeyValues:[message mj_keyValues]];
            //接收成功
            chatMsg.messageSended=SEND_STATE_PUSHED;
            //获取之前的消息ID
            ChatMessage* former=[[FlappyDataBase shareInstance]getMessageByID:chatMsg.messageId];
            //之前不存在
            if(former==nil){
                //添加数据
                [[FlappyDataBase shareInstance] insert:chatMsg];
                [self notifyNewMessage:chatMsg];
                [self sendMessageArrive:chatMsg];
            }else{
                [[FlappyDataBase shareInstance] updateMessage:chatMsg];
            }
            ChatUser* user=[FlappyData getUser];
            user.latest=[NSString stringWithFormat:@"%ld",(long)chatMsg.messageTableSeq];
            [FlappyData saveUser:user];
        }
    }
}
//发送已经到达的消息
-(void)sendMessageArrive:(ChatMessage*)message{
    //判断当前是在后台还是前台，如果是在后台，那么
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    //如果再后台
    if(state == UIApplicationStateActive ){
        //存活状态才返回信息
        ChatUser* user=[FlappyData getUser];
        if(user!=nil&&![user.userId isEqualToString:message.messageSend]){
            //连接到服务器开始请求登录
            FlappyRequest* request=[[FlappyRequest alloc]init];
            //登录请求
            request.type=REQ_RECIEVE;
            request.latest=[NSString stringWithFormat:@"%ld",(long)message.messageTableSeq];
            //请求数据，已经GPBComputeRawVarint32SizeForInteger
            NSData* reqData=[request delimitedData];
            //写入数据请求
            [self.socket writeData:reqData withTimeout:-1 tag:0];
        }
    }
}

//通知有新的消息
-(void)notifyNewMessage:(ChatMessage*)message{
    //在主线程之中执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //新消息
            NSArray* array=[FlappyIM shareInstance].callbacks.allKeys;
            //数量
            for(int s=0;s<array.count;s++){
                NSString* str=[array objectAtIndex:s];
                NSMutableArray* listeners=[[FlappyIM shareInstance].callbacks objectForKey:str];
                //回调监听的事件
                for(int w=0;w<listeners.count;w++){
                    MessageListener listener=[listeners objectAtIndex:w];
                    listener(message);
                }
            }
        });
    });
}




#pragma heart beat  心跳
//开启心跳
-(void)startHeart:(id)sender{
    // 开启心跳
    // 每隔30s像服务器发送心跳包
    // 在longConnectToSocket方法中进行长连接需要向服务器发送的讯息
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:10
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
