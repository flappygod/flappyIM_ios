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
#import "FlappyApiConfig.h"


@interface FlappyIM ()

//用于监听网络变化
@property (nonatomic,strong) Reachability* hostReachability;
//用于监听网络变化
@property (nonatomic,strong) Reachability* internetReachability;


@property (nonatomic,strong) FlappySocket* flappysocket;


//被踢下线了
@property (nonatomic,strong) FlappyKnicked knicked;


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

//设置被踢下线的监听
-(void)setKnickedListener:(__nullable FlappyKnicked)knicked{
    //保留
    _knicked=knicked;
    //查看当前的登录状态
    ChatUser* user=[FlappyData getUser];
    //用户存在，但是登录状态不对，代表已经被踢下线了
    if(user!=nil&&user.login==false){
        if(self.knicked!=nil){
            self.knicked();
        }
    }
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


//初始化
-(void)setup:(NSString*)serverUrl  withUploadUrl:(NSString*)uploadUrl{
    //重新设置服务器地址
    [[FlappyApiConfig shareInstance] resetServer:serverUrl andUploadUrl:uploadUrl];
    
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
    
    //当前用户没有登录或者被踢下线的情况
    if(user==nil||user.login==false){
        return;
    }
    //当前是已经连接的，不需要继续登录了
    if(self.flappysocket!=nil){
        //不为空而且已经连接，不需要继续登录了
        if(self.flappysocket.socket!=nil&&self.flappysocket.socket.isConnected){
            return;
        }
    }
    //开始
    __weak typeof(self) safeSelf=self;
    //如果网络是正常连接的
    if([NetTool getCurrentNetworkState]!=0){
        //防止重复请求
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


//创建账号
-(void)createAccount:(NSString*)userID
         andUserName:(NSString*)userName
         andUserHead:(NSString*)userHead
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure{
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_register;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendID":userID,
                                 @"userName":userName,
                                 @"userHead":userHead
                                 };
    
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:success
                      withFailure:failure];
    
}



//登录账号
-(void)login:(NSString*)userExtendID
  andSuccess:(FlappySuccess)success
  andFailure:(FlappyFailure)failure{
    
    
    //当前有flappysocket，而且正在登录
    if(self.flappysocket!=nil&&(self.flappysocket.success!=nil||self.flappysocket.failure!=nil)){
        
        //直接失败
        failure([NSError errorWithDomain:@"A login thread also run"
                                    code:RESULT_NETERROR
                                userInfo:nil],RESULT_NETERROR);
        return ;
    }
    
    //如果当前有正在连接的socket,先下线了
    if(self.flappysocket!=nil){
        //之前的正常下线
        [self.flappysocket offline:true];
    }
    
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_login;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":@"",
                                 @"userExtendID":userExtendID,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":self.pushID
                                 };
    
    
    //创建
    self.flappysocket=[[FlappySocket alloc] init];
    
    __weak typeof(self) safeSelf=self;
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          
                          //得到当前的用户数据
                          NSDictionary* dic=data[@"user"];
                          //用户
                          ChatUser* user=[ChatUser mj_objectWithKeyValues:dic];
                          //登录成功
                          user.login=true;
                          
                          
                          safeSelf.flappysocket.loginData=data;
                          //连接服务器
                          [safeSelf.flappysocket connectSocket:data[@"serverIP"]
                                                      withPort:data[@"serverPort"]
                                                      withUser:user
                                                   withSuccess:success
                                                   withFailure:failure
                                                          dead:^{
                                                              [safeSelf performSelectorOnMainThread:@selector(setupReconnect)
                                                                                         withObject:nil
                                                                                      waitUntilDone:false];
                                                          }];
                          
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
}


//退出登录下线
-(void)logout:(FlappySuccess)success
   andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //之前的正常下线
    [self.flappysocket offline:true];
    
    //清空
    self.flappysocket=nil;
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_logout;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":@"",
                                 @"userExtendID":[FlappyData getUser].userExtendId,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":self.pushID
                                 };
    //请求数据
    [FlappyApiRequest postRequest:urlString
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
    
    
    //当前有flappysocket，而且正在登录
    if(self.flappysocket!=nil&&(self.flappysocket.success!=nil||self.flappysocket.failure!=nil)){
        
        //直接失败
        failure([NSError errorWithDomain:@"A login thread also run"
                                    code:RESULT_NETERROR
                                userInfo:nil],RESULT_NETERROR);
        return ;
    }
    
    //如果当前有正在连接的socket,先下线了
    if(self.flappysocket!=nil){
        //之前的正常下线
        [self.flappysocket offline:true];
    }
    
    
    //自动登录
    NSString *urlString = [FlappyApiConfig shareInstance].URL_autoLogin;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":[FlappyData getUser].userId,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":self.pushID
                                 };
    
    //创建新的
    self.flappysocket=[[FlappySocket alloc] init];
    
    __weak typeof(self) safeSelf=self;
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          
                          //得到当前的用户数据
                          NSDictionary* dic=data[@"user"];
                          //用户
                          ChatUser* user=[ChatUser mj_objectWithKeyValues:dic];
                          //更新信息
                          ChatUser* newUser=[FlappyData getUser];
                          //最后的时间保存起来
                          newUser.userName=user.userName;
                          //头像
                          newUser.userHead=user.userHead;
                          //登录成功的
                          newUser.login =true;
                          
                          //保存
                          [FlappyData saveUser:newUser];
                          
                          
                          //设置登录返回的数据
                          safeSelf.flappysocket.loginData=data;
                          //连接服务器
                          [safeSelf.flappysocket connectSocket:data[@"serverIP"]
                                                      withPort:data[@"serverPort"]
                                                      withUser:user
                                                   withSuccess:success
                                                   withFailure:failure
                                                          dead:^{
                                                              
                                                              [safeSelf performSelectorOnMainThread:@selector(setupReconnect)
                                                                                         withObject:nil
                                                                                      waitUntilDone:false];
                                                              
                                                          }];
                          
                          
                          
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
}



//创建两个人的会话
-(void)createSingleSession:(NSString*)userTwo
                andSuccess:(FlappySuccess)success
                andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_createSingleSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userOne":[FlappyData getUser].userExtendId,
                                 @"userTwo":userTwo,
                                 };
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          //获取model
                          SessionData* model=[SessionData mj_objectWithKeyValues:data];
                          //创建session
                          FlappyChatSession* session=[FlappyChatSession mj_objectWithKeyValues:data];
                          session.session=model;
                          success(session);
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
}


-(void)getSingleSession:(NSString*)userTwo
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getSingleSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userOne":[FlappyData getUser].userExtendId,
                                 @"userTwo":userTwo,
                                 };
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          //获取model
                          SessionData* model=[SessionData mj_objectWithKeyValues:data];
                          //创建session
                          FlappyChatSession* session=[FlappyChatSession mj_objectWithKeyValues:data];
                          session.session=model;
                          success(session);
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
}


//创建群组会话
-(void)createGroupSession:(NSString*)users
              withGroupID:(NSString*)groupID
            withGroupName:(NSString*)groupName
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_createGroupSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"users":users,
                                 @"createUser":[FlappyData getUser].userId,
                                 @"extendID":groupID,
                                 @"sessionName":groupName
                                 };
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          //获取model
                          SessionData* model=[SessionData mj_objectWithKeyValues:data];
                          //创建session
                          FlappyChatSession* session=[FlappyChatSession mj_objectWithKeyValues:data];
                          session.session=model;
                          success(session);
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
    
}


//获取群组会话
-(void)getSessionByID:(NSString*)groupID
           andSuccess:(FlappySuccess)success
           andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getSessionByID;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"extendID":groupID};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          //获取model
                          SessionData* model=[SessionData mj_objectWithKeyValues:data];
                          //创建session
                          FlappyChatSession* session=[FlappyChatSession mj_objectWithKeyValues:data];
                          //数据
                          session.session=model;
                          //成功
                          success(session);
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
}

//获取用户的sessions
-(void)getUserSessions:(FlappySuccess)success
            andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getUserSessions;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendID":[FlappyData getUser].userExtendId};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          //解析
                          NSArray* array=data;
                          NSMutableArray* sessions=[[NSMutableArray alloc]init];
                          for(int s=0;s<array.count;s++){
                              [sessions addObject:[ChatSession mj_objectWithKeyValues:[array objectAtIndex:s]]];
                          }
                          //成功
                          success(sessions);
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
}


//添加用户到群组
-(void)addUserToSession:(NSString*)userID
            withGroupID:(NSString*)groupID
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_addUserToSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"extendID":groupID,@"userID":userID};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          //获取model
                          SessionData* model=[SessionData mj_objectWithKeyValues:data];
                          //创建session
                          FlappyChatSession* session=[FlappyChatSession mj_objectWithKeyValues:data];
                          //数据
                          session.session=model;
                          //成功
                          success(session);
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
}

//删除会话
-(void)delUserInSession:(NSString*)userID
            withGroupID:(NSString*)groupID
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([FlappyData getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"账户未登录" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_delUserInSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"extendID":groupID,@"userID":userID};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
                          //获取model
                          SessionData* model=[SessionData mj_objectWithKeyValues:data];
                          //创建session
                          FlappyChatSession* session=[FlappyChatSession mj_objectWithKeyValues:data];
                          //数据
                          session.session=model;
                          //成功
                          success(session);
                      } withFailure:^(NSError * error, NSInteger code) {
                          //登录失败，清空回调
                          failure(error,code);
                      }];
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
    [self.flappysocket  offline:false];
    //停止
    [self  stopOberver];
    //清空
    [self.callbacks removeAllObjects];
}


@end
