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


@interface FlappyIM ()

//socket通信
@property (nonatomic,strong) GCDAsyncSocket*  socket;
//当前登录的lock
@property (nonatomic,assign) Boolean  loginLock;

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
    _sharedSingleton.loginLock=false;
    return _sharedSingleton;
}


//请求接口
-(void)postRequest:(NSString*)url
    withParameters:(NSDictionary *)param
       withSuccess:(FlappySuccess)success
       withFailure:(FlappyFailure)failure{
    
    
    //初始化一个AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //设置请求体数据为json类型
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置响应体数据为json类型
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    //请求数据
    [manager POST:url
       parameters:param
         progress:^(NSProgress * _Nonnull uploadProgress) {
             
         } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             //请求成功
             if(responseObject!=nil&&[responseObject[@"resultCode"] integerValue]==1){
                 //数据请求成功
                 success(responseObject[@"resultData"]);
             }else{
                 //请求失败
                 failure([[NSError alloc]initWithDomain:responseObject[@"resultMessage"]
                                                   code:RESULT_FAILURE
                                               userInfo:nil],
                         RESULT_FAILURE);
             }
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             //网络错误请求失败
             failure(error,RESULT_NETERROR);
         }];
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
    [self postRequest:urlString
       withParameters:parameters
          withSuccess:success
          withFailure:failure];
    
}



//登录账号
-(void)login:(NSString*)userExtendID
  andSuccess:(FlappySuccess)success
  andFailure:(FlappyFailure)failure{
    //注册地址
    NSString *urlString = URL_login;
    
    NSString *pushID=@"123456789";
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":@"",
                                 @"userExtendID":userExtendID,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":pushID,
                                 };
    
    self.loginLock=true;
    __weak typeof(self) safeSelf=self;
    //请求数据
    [self postRequest:urlString
       withParameters:parameters
          withSuccess:^(id data) {
              
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
              safeSelf.loginLock=false;
              failure(error,code);
          }];
}


//建立长连接
-(void)connectSocket:(NSString*)serverAddress
            withPort:(NSString*)serverPort
            withUser:(User*)user
         withSuccess:(FlappySuccess)success
         withFailure:(FlappyFailure)failure{
    
    //建立长连接
    _socket=[[GCDAsyncSocket alloc] initWithDelegate:self
                                       delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    NSError* error=nil;
    
    //连接host
    [_socket connectToHost:serverAddress
                    onPort:serverPort.integerValue
               withTimeout:20
                     error:&error];
    
    if(error!=nil){
        NSLog(@"%@",error.description);
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
    
    NSLog(@"adwa");
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url{
    
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
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

/**
 * Called if a read operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the read's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the read will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been read so far for the read operation.
 *
 * Note that this method may be called multiple times for a single read if you return positive numbers.
 **/
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


@end