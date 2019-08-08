//
//  FlappyIM.m
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import "FlappyIM.h"
#import "ApiConfig.h"
#import "User.h"
#import "MJExtension.h"
#import <AFNetworking/AFNetworking.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "Flappy.pbobjc.h"
#import "FlappyData.h"
#import "NetTool.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Reachability/Reachability.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>


@interface FlappyIM ()

//用于监听网络变化
@property (nonatomic,strong) Reachability* hostReachability;
@property (nonatomic,strong) Reachability* internetReachability;
//socket通信
@property (nonatomic,strong) GCDAsyncSocket*  socket;
//推送的ID
@property (nonatomic,copy) NSString*  pushID;


//读取的数据
@property (nonatomic,strong) NSMutableData*  receiveData;
//心跳计时
@property (nonatomic,strong) NSTimer*  connectTimer;
//正在登录的用户
@property (nonatomic,strong) User*  user;
//登录的数据
@property (nonatomic,strong) id  loginData;
//登录成功之后非正常退出的情况
@property (nonatomic,strong) FlappyDead  dead;
//成功
@property (nonatomic,strong) FlappySuccess  success;
//失败
@property (nonatomic,strong) FlappyFailure  failure;

@end


@implementation FlappyIM


//使用单例模式
+ (instancetype)shareInstance {
    static FlappyIM *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        _sharedSingleton = [[super allocWithZone:NULL] init];
    });
    //false
    _sharedSingleton.pushID=@"123456";
    _sharedSingleton.receiveData=[[NSMutableData alloc]init];
    return _sharedSingleton;
}


// 防止外部调用alloc或者new
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [FlappyIM shareInstance];
}

// 防止外部调用copy
- (id)copyWithZone:(nullable NSZone *)zone {
    return [FlappyIM shareInstance];
}

// 防止外部调用mutableCopy
- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [FlappyIM shareInstance];
}


//初始化
-(void)setup{
    //重新连接
    [self setupReconnect];
    //通知
    [self setupNotify];
}



#pragma  NOTIFY 网络状态监听通知
-(void)setupNotify{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    // 设置网络检测的站点
    NSString *remoteHostName = @"www.baidu.com";
    //创建
    self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
    [self.hostReachability startNotifier];
    [self updateInterfaceWithReachability:self.hostReachability];
    //创建
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self updateInterfaceWithReachability:self.internetReachability];
}
//变化监听
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    [self updateInterfaceWithReachability:curReach];
}
//更新网络状态
- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    switch (netStatus) {
        case 0:
            break;
        case 1:
            [self performSelector:@selector(setupReconnect) withObject:nil afterDelay:3];
            break;
        case 2:
            [self performSelector:@selector(setupReconnect) withObject:nil afterDelay:3];
            break;
        default:
            break;
    }
}
//停止监听
-(void)stopOberver{
    //移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:nil];
}

//进行初始化
-(void)setupReconnect{
    //自动登录
    User* user=[FlappyData getUser];
    //用户之前已经登录过
    if(user==nil||user.login==false){
        return;
    }
    //开始
    __weak typeof(self) safeSelf=self;
    //如果网络是正常连接的
    if([NetTool getCurrentNetworkState]!=0){
        //防止重复请求
        if(self.success!=nil||self.failure!=nil){
            [self autoLogin:^(id data) {
                NSLog(@"自动登录成功");
            } andFailure:^(NSError * error, NSInteger code) {
                //3秒后重新执行登录
                [safeSelf performSelector:@selector(setupReconnect)
                               withObject:nil
                               afterDelay:3];
            }];
        }
    }
}


//创建账号
-(void)createAccount:(NSString*)userID
         andUserName:(NSString*)userName
         andUserHead:(NSString*)userHead
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure{
    
    //注册地址
    NSString *urlString = URL_register;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendID":userID,
                                 @"userName":userName,
                                 @"userHead":userHead
                                 };
    
    //请求数据
    [PostTool postRequest:urlString
       withParameters:parameters
          withSuccess:success
          withFailure:failure];
    
}



//登录账号
-(void)login:(NSString*)userExtendID
  andSuccess:(FlappySuccess)success
  andFailure:(FlappyFailure)failure{
    
    //登录成功或者失败的回调没有执行
    if(self.success!=nil||self.failure!=nil){
        //直接失败
        failure([NSError errorWithDomain:@"A login thread also run"
                                    code:RESULT_NETERROR
                                userInfo:nil],RESULT_NETERROR);
        return ;
    }
    
    //注册地址
    NSString *urlString = URL_login;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":@"",
                                 @"userExtendID":userExtendID,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":self.pushID,
                                 };
    //赋值给当前的回调
    self.success=success;
    self.failure = failure;
    
    __weak typeof(self) safeSelf=self;
    //请求数据
    [PostTool postRequest:urlString
       withParameters:parameters
          withSuccess:^(id data) {
              
              //赋值登录数据
              safeSelf.loginData=data;
              //得到当前的用户数据
              NSDictionary* dic=data[@"user"];
              //用户
              User* user=[User mj_objectWithKeyValues:dic];
              //连接服务器
              [self connectSocket:data[@"serverIP"]
                         withPort:data[@"serverPort"]
                         withUser:user
                      withSuccess:success
                      withFailure:failure];
              
          } withFailure:^(NSError * error, NSInteger code) {
              //登录失败，清空回调
              failure(error,code);
              safeSelf.success=nil;
              safeSelf.failure =nil;
          }];
}

//自动登录
-(void)autoLogin:(FlappySuccess)success
      andFailure:(FlappyFailure)failure{
    //登录成功或者失败的回调没有执行
    if(self.success!=nil||self.failure!=nil){
        //直接失败
        failure([NSError errorWithDomain:@"A login thread also run"
                                    code:RESULT_NETERROR
                                userInfo:nil],RESULT_NETERROR);
        return ;
    }
    
    
    //自动登录
    NSString *urlString = URL_autoLogin;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":[FlappyData getUser].userId,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":self.pushID,
                                 };
    //赋值给当前的回调
    self.success=success;
    self.failure = failure;
    
    __weak typeof(self) safeSelf=self;
    //请求数据
    [PostTool postRequest:urlString
       withParameters:parameters
          withSuccess:^(id data) {
              
              //赋值登录数据
              safeSelf.loginData=data;
              //得到当前的用户数据
              NSDictionary* dic=data[@"user"];
              //用户
              User* user=[User mj_objectWithKeyValues:dic];
              //用户正常下线
              [safeSelf offline:true];
              //用户下线之后重新连接服务器
              [safeSelf connectSocket:data[@"serverIP"]
                             withPort:data[@"serverPort"]
                             withUser:user
                          withSuccess:success
                          withFailure:failure];
              
              
          } withFailure:^(NSError * error, NSInteger code) {
              //登录失败，清空回调
              failure(error,code);
              safeSelf.success=nil;
              safeSelf.failure =nil;
          }];
}


//建立长连接
-(void)connectSocket:(NSString*)serverAddress
            withPort:(NSString*)serverPort
            withUser:(User*)user
         withSuccess:(FlappySuccess)success
         withFailure:(FlappyFailure)failure{
    
    
    //建立长连接
    self.socket=[[GCDAsyncSocket alloc] initWithDelegate:self
                                           delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
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
        //非正常退出的时候，延迟重新执行
        __weak typeof(self) safeSelf=self;
        //socket非正常退出的时候，重新登录
        self.dead = ^{
            //3秒后重新执行登录
            [safeSelf performSelector:@selector(setupReconnect)
                           withObject:nil
                           afterDelay:3];
        };
    }
    
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




#pragma GCDAsyncSocketDelegate

/**
 * Called when a socket accepts a connection.
 * Another socket is automatically spawned to handle it.
 *
 * You must retain the newSocket if you wish to handle the connection.
 * Otherwise the newSocket instance will be released and the spawned connection will be closed.
 *
 * By default the new socket will have the same delegate and delegateQueue.
 * You may, of course, change this at any time.
 **/
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    //组装登录数据
    LoginInfo* info=[[LoginInfo alloc]init];
    //类型
    info.device=DEVICE_TYPE;
    //用户ID
    info.userId=self.user.userId;
    //推送ID
    info.pushid=self.pushID;
    

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
    //开启心跳线程
    [self performSelectorOnMainThread:@selector(startHeart:)
                           withObject:nil waitUntilDone:false];
    
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
    int32_t contentL = [self getContentLength:self.receiveData withHeadLength:&headL];
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
    [sock readDataWithTimeout:-1 tag:tag];
    
}

/**
 * Called when a socket has read in data, but has not yet completed the read.
 * This would occur if using readToData: or readToLength: methods.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}

/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    return 10;
}

/**
 * Called if a write operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the write's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the write will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been written so far for the write operation.
 *
 * Note that this method may be called multiple times for a single write if you return positive numbers.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    
    return 10;
}

/**
 * Conditionally called if the read stream closes, but the write stream may still be writeable.
 *
 * This delegate method is only called if autoDisconnectOnClosedReadStream has been set to NO.
 * See the discussion on the autoDisconnectOnClosedReadStream method for more information.
 **/
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
    
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * then an invocation of this delegate method will be enqueued on the delegateQueue
 * before the disconnect method returns.
 *
 * Note: If the GCDAsyncSocket instance is deallocated while it is still connected,
 * and the delegate is not also deallocated, then this method will be invoked,
 * but the sock parameter will be nil. (It must necessarily be nil since it is no longer available.)
 * This is a generally rare, but is possible if one writes code like this:
 *
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * In this case it may preferrable to nil the delegate beforehand, like this:
 *
 * asyncSocket.delegate = nil; // Don't invoke my delegate method
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * Of course, this depends on how your state machine is configured.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    //非正常d退出
    [self offline:false];
}

/**
 * Called after the socket has successfully completed SSL/TLS negotiation.
 * This method is not called unless you use the provided startTLS method.
 *
 * If a SSL/TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
 * and the socketDidDisconnect:withError: delegate method will be called with the specific SSL error code.
 **/
- (void)socketDidSecure:(GCDAsyncSocket *)sock{
    
}

/**
 * Allows a socket delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
 *
 * This is only called if startTLS is invoked with options that include:
 * - GCDAsyncSocketManuallyEvaluateTrust == YES
 *
 * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
 *
 * Note from Apple's documentation:
 *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
 *   [it] might block while attempting network access. You should never call it from your main thread;
 *   call it only from within a function running on a dispatch queue or on a separate thread.
 *
 * Thus this method uses a completionHandler block rather than a normal return value.
 * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
 * It is safe to invoke the completionHandler block even if the socket has been closed.
 **/
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
    //非正常退出
    if(self.dead!=nil){
        //非正常退出
        self.dead();
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
}



/** 解析二进制数据：NSData --> 自定义模型对象 */
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
            [self saveReceiveInfo:obj];
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
    contentL = [self getContentLength:self.receiveData
                       withHeadLength:&headL];
    //实际包不足解析，继续接收下一个包
    if (headL + contentL > self.receiveData.length) return;
    //继续解析下一条
    [self parseContentDataWithHeadLength:headL
                       withContentLength:contentL];
}

/** 获取data数据的内容长度和头部长度: index --> 头部占用长度 (头部占用长度1-4个字节) */
- (int32_t)getContentLength:(NSData *)data withHeadLength:(int32_t *)index{
    int8_t tmp = [self readRawByte:data headIndex:index];
    if (tmp >= 0) return tmp;
    int32_t result = tmp & 0x7f;
    if ((tmp = [self readRawByte:data headIndex:index]) >= 0) {
        result |= tmp << 7;
    } else {
        result |= (tmp & 0x7f) << 7;
        if ((tmp = [self readRawByte:data headIndex:index]) >= 0) {
            result |= tmp << 14;
        } else {
            result |= (tmp & 0x7f) << 14;
            if ((tmp = [self readRawByte:data headIndex:index]) >= 0) {
                result |= tmp << 21;
            } else {
                result |= (tmp & 0x7f) << 21;
                result |= (tmp = [self readRawByte:data headIndex:index]) << 28;
                if (tmp < 0) {
                    for (int i = 0; i < 5; i++) {
                        if ([self readRawByte:data headIndex:index] >= 0) {
                            return result;
                        }
                    }
                    result = -1;
                }
            }
        }
    }
    return result;
}

/** 读取字节 */
- (int8_t)readRawByte:(NSData *)data headIndex:(int32_t *)index{
    if (*index >= data.length) return -1;
    *index = *index + 1;
    return ((int8_t *)data.bytes)[*index - 1];
}

/** 处理解析出来的信息 */
- (void)saveReceiveInfo:(FlappyResponse *)respones{
    //返回登录消息
    if(respones.type==RES_LOGIN)
    {
        //登录成功
        if(self.success!=nil){
            
            //用户已经登录过了
            self.user.login=true;
            //保存用户登录数据
            [FlappyData saveUser:self.user];
            
            self.success(self.loginData);
            //清空回调和数据
            self.success=nil;
            self.failure=nil;
            self.loginData=nil;
        }
        //消息信息
        NSMutableArray* array=respones.msgArray;
        for(int s=0;s<array.count;s++){
            Message* message=[array objectAtIndex:s];
            NSLog(@"%@",message.messageContent);
        }
    }
    //接收到新的消息
    else if(respones.type==RES_MSG){
        
        
    }
}



#pragma  dealloc
//清空
-(void)dealloc{
    [self  offline:false];
    [self  stopOberver];
}


@end
