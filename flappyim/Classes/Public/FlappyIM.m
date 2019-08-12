//
//  FlappyIM.m
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import "FlappyIM.h"

#import "MJExtension.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "FlappyConfig.h"
#import "FlappyData.h"
#import "DataBase.h"
#import "NetTool.h"
#import "FlappySender.h"


@interface FlappyIM ()

@property (nonatomic,strong) FlappyKnicked* knicked;
//用于监听网络变化
@property (nonatomic,strong) Reachability* hostReachability;
//用于监听网络变化
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
@property (nonatomic,strong) ChatUser*  user;
//登录的数据
@property (nonatomic,strong) id  loginData;
//登录成功之后非正常退出的情况
@property (nonatomic,strong) FlappyDead  dead;
//成功
@property (nonatomic,strong) FlappySuccess  success;
//失败
@property (nonatomic,strong) FlappyFailure  failure;
//回调
@property (nonatomic,strong) NSMutableDictionary*  callbacks;


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
        //推送ID
        _sharedSingleton.pushID=@"123456";
        _sharedSingleton.receiveData=[[NSMutableData alloc]init];
        _sharedSingleton.callbacks=[[NSMutableDictionary alloc] init];
    });
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
    //初始化数据库
    [self setupDataBase];
}

//增加消息的监听
-(void)addGloableListener:(MessageListener)listener{
    //监听所有消息
    if(listener!=nil){
        //获取当前的监听列表
        NSMutableArray* listeners=[self.callbacks objectForKey:@""];
        //创建新的监听
        if(listeners==nil){
            //设置监听
            listeners=[[NSMutableArray alloc]init];
            [self.callbacks setObject:listeners forKey:@""];
        }
        //添加监听
        if(listener!=nil){
            [listeners addObject:listener];
        }
    }
}

//移除监听
-(void)removeGloableListener:(MessageListener)listener{
    //监听所有消息
    if(listener!=nil){
        //获取当前的监听列表
        NSMutableArray* listeners=[self.callbacks objectForKey:@""];
        //创建新的监听
        if(listeners==nil){
            //设置监听
            listeners=[[NSMutableArray alloc]init];
            [self.callbacks setObject:listeners forKey:@""];
        }
        //添加监听
        if(listener!=nil){
            [listeners removeObject:listener];
        }
    }
}

//增加某个session的监听
-(void)addListener:(MessageListener)listener
     withSessionID:(NSString*)sessionID{
    //监听所有消息
    if(listener!=nil){
        //获取当前的监听列表
        NSMutableArray* listeners=[self.callbacks objectForKey:sessionID];
        //创建新的监听
        if(listeners==nil){
            //设置监听
            listeners=[[NSMutableArray alloc]init];
            [self.callbacks setObject:listeners forKey:sessionID];
        }
        //添加监听
        if(listener!=nil){
            [listeners addObject:listener];
        }
    }
}

//移除会话的
-(void)removeListener:(MessageListener)listener
        withSessionID:(NSString*)sessionID{
    //监听所有消息
    if(listener!=nil){
        //获取当前的监听列表
        NSMutableArray* listeners=[self.callbacks objectForKey:sessionID];
        //创建新的监听
        if(listeners==nil){
            //设置监听
            listeners=[[NSMutableArray alloc]init];
            [self.callbacks setObject:listeners forKey:sessionID];
        }
        //添加监听
        if(listener!=nil){
            [listeners removeObject:listener];
        }
    }
}

#pragma database
-(void)setupDataBase{
    //初始化数据库
    [[DataBase shareInstance] setup];
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
            [self performSelector:@selector(setupReconnect) withObject:nil afterDelay:1];
            break;
        case 2:
            [self performSelector:@selector(setupReconnect) withObject:nil afterDelay:1];
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
    ChatUser* user=[FlappyData getUser];
    //用户之前已经登录过
    if(user==nil||user.login==false){
        return;
    }
    //当前是已经连接的，不需要继续登录了
    if(self.socket!=nil&&self.socket.isConnected){
        return;
    }
    //开始
    __weak typeof(self) safeSelf=self;
    //如果网络是正常连接的
    if([NetTool getCurrentNetworkState]!=0){
        //防止重复请求
        if(self.success==nil&&self.failure==nil){
            [self autoLogin:^(id data) {
                NSLog(@"自动登录成功");
            } andFailure:^(NSError * error, NSInteger code) {
                //当前账户已经被踢下线了
                if(code==RESULT_KNICKED){
                    //清空user
                    ChatUser* uesr=[FlappyData getUser];
                    uesr.login=false;
                    [FlappyData saveUser:uesr];
                    //当前账户被踢下线
                    if(self.knicked!=nil){
                        self.knicked();
                        self.knicked=nil;
                    }
                }else{
                    //3秒后重新执行登录
                    [safeSelf performSelector:@selector(setupReconnect)
                                   withObject:nil
                                   afterDelay:5];
                }
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
    
    //之前的正常下线
    [self offline:true];
    
    //登录成功或者失败的回调没有执行
    if(self.success!=nil||self.failure!=nil){
        //直接失败
        failure([NSError errorWithDomain:@"A login thread also run"
                                    code:RESULT_NETERROR
                                userInfo:nil],RESULT_NETERROR);
        return ;
    }
    
    //赋值给当前的回调
    self.success=success;
    self.failure = failure;
    
    //注册地址
    NSString *urlString = URL_login;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":@"",
                                 @"userExtendID":userExtendID,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":self.pushID
                                 };
    
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
                  ChatUser* user=[ChatUser mj_objectWithKeyValues:dic];
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


//退出登录下线
-(void)logout:(NSString*)userExtendID
   andSuccess:(FlappySuccess)success
   andFailure:(FlappyFailure)failure{
    
    //之前的正常下线
    [self offline:true];
    //注册地址
    NSString *urlString = URL_logout;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":@"",
                                 @"userExtendID":userExtendID,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":self.pushID
                                 };
    //请求数据
    [PostTool postRequest:urlString
           withParameters:parameters
              withSuccess:^(id data) {
                  //退出登录成功
                  success(data);
                  //清空当前相应的用户信息
                  [FlappyData clearUser];
              } withFailure:^(NSError * error, NSInteger code) {
                  //登录失败，清空回调
                  failure(error,code);
              }];
    
}

//自动登录
-(void)autoLogin:(FlappySuccess)success
      andFailure:(FlappyFailure)failure{
    
    
    //之前的正常下线
    [self offline:true];
    
    //登录成功或者失败的回调没有执行
    if(self.success!=nil||self.failure!=nil){
        //直接失败
        failure([NSError errorWithDomain:@"A login thread also run"
                                    code:RESULT_NETERROR
                                userInfo:nil],RESULT_NETERROR);
        return ;
    }
    
    //赋值给当前的回调
    self.success = success;
    self.failure = failure;
    
    //自动登录
    NSString *urlString = URL_autoLogin;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":[FlappyData getUser].userId,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":self.pushID
                                 };
    
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
                  ChatUser* user=[ChatUser mj_objectWithKeyValues:dic];
                  //最后的时间保存起来
                  user.latest=[FlappyData getUser].latest;
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



//创建两个人的会话
-(void)createSession:(NSString*)userTwo
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录"
                                    code:0
                                userInfo:nil],
                RESULT_NOTLOGIN);
        return ;
    }
    
    //注册地址
    NSString *urlString = URL_createSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userOne":[FlappyData getUser].userExtendId,
                                 @"userTwo":userTwo,
                                 };
    //请求数据
    [PostTool postRequest:urlString
           withParameters:parameters
              withSuccess:^(id data) {
                  //获取model
                  SessionModel* model=[SessionModel mj_objectWithKeyValues:data];
                  //创建session
                  FlappySession* session=[FlappySession mj_objectWithKeyValues:data];
                  session.userOne=[FlappyData getUser].userExtendId;
                  session.userTwo=model.userTwo.userExtendId;
                  session.session=model;
                  success(session);
              } withFailure:^(NSError * error, NSInteger code) {
                  //登录失败，清空回调
                  failure(error,code);
              }];
}



//建立长连接
-(void)connectSocket:(NSString*)serverAddress
            withPort:(NSString*)serverPort
            withUser:(ChatUser*)user
         withSuccess:(FlappySuccess)success
         withFailure:(FlappyFailure)failure{
    
    
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
        //非正常退出的时候，延迟重新执行
        __weak typeof(self) safeSelf=self;
        //socket非正常退出的时候，重新登录
        self.dead = ^{
            //主线程中重新开始联网判断
            [safeSelf performSelectorOnMainThread:@selector(setupReconnect)
                                       withObject:nil
                                    waitUntilDone:false];
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
    info.pushid=self.pushID;
    
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
    int32_t contentL = [PostTool getContentLength:self.receiveData
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
    //保存
    [FlappySender shareInstance].socket=nil;
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
    contentL = [PostTool getContentLength:self.receiveData
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
            if(one.messageTableSeq.integerValue>two.messageTableSeq.integerValue){
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
            chatMsg.messageSended=SEND_STATE_REACHED;
            //获取之前的消息ID
            ChatMessage* former=[[DataBase shareInstance]getMessageByID:chatMsg.messageId];
            //之前不存在
            if(former==nil){
                //添加数据
                [[DataBase shareInstance] insert:chatMsg];
                [self notifyNewMessage:chatMsg];
            }else{
                [[DataBase shareInstance] updateMessage:chatMsg];
            }
        }
        //最后一条的数据保存
        if(array.count>0){
            ChatMessage* last=[array objectAtIndex:array.count-1];
            self.user.latest=last.messageTableSeq;
            [FlappyData saveUser:self.user];
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
            chatMsg.messageSended=SEND_STATE_REACHED;
            //获取之前的消息ID
            ChatMessage* former=[[DataBase shareInstance]getMessageByID:chatMsg.messageId];
            //之前不存在
            if(former==nil){
                //添加数据
                [[DataBase shareInstance] insert:chatMsg];
                [self notifyNewMessage:chatMsg];
            }else{
                [[DataBase shareInstance] updateMessage:chatMsg];
            }
            //保存最近的时间
            self.user.latest=[NSString stringWithFormat:@"%ld",(long)chatMsg.messageTableSeq];
            //保存最近的时间
            [FlappyData saveUser:self.user];
        }
    }
}

//通知有新的消息
-(void)notifyNewMessage:(ChatMessage*)message{
    //在主线程之中执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //新消息
            NSArray* array=self.callbacks.allKeys;
            //数量
            for(int s=0;s<array.count;s++){
                NSString* str=[array objectAtIndex:s];
                NSMutableArray* listeners=[self.callbacks objectForKey:str];
                //回调监听的事件
                for(int w=0;w<listeners.count;w++){
                    MessageListener listener=[listeners objectAtIndex:w];
                    listener(message);
                }
            }
        });
    });
}

//判断当前用户是否登录
-(Boolean)isLogin{
    //获取当前账户
    ChatUser* user=[FlappyData getUser];
    //如果当前账户不是登录的状态
    if(user==nil||user.login==false){
        return false;
    }
    //返回状态
    return true;
}

#pragma  dealloc
//销毁逻辑
-(void)dealloc{
    //下线
    [self  offline:false];
    //停止
    [self  stopOberver];
    //清空
    [self.callbacks removeAllObjects];
}


@end
