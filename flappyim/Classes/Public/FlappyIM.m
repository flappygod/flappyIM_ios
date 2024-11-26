//
//  FlappyIM.m
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//
#import "FlappyIM.h"
#import <Security/Security.h>
#import "MJExtension.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "FlappyJsonTool.h"
#import "FlappyConfig.h"
#import "FlappyData.h"
#import "FlappyDataBase.h"
#import "FlappyNetTool.h"
#import "FlappySender.h"
#import "FlappyApiConfig.h"
#import "FlappyStringTool.h"
#import "FlappyFailureWrap.h"
#import "FlappyDef.h"



@interface FlappyIM ()

//用于监听网络变化
@property (nonatomic,strong) FlappyReachability* hostReachability;
//用于联网的socket
@property (nonatomic,strong) FlappySocket* flappysocket;
//被踢下线了
@property (nonatomic,strong) FlappyKnicked knicked;
//消息通知被点击了
@property (nonatomic,strong) NotifyClickListener notifyClicked;
//被踢下线了
@property (nonatomic,assign) bool isSetup;
//当前正在登录
@property (nonatomic,assign) bool isRunningLogin;
//当前正在登录
@property (nonatomic,assign) bool isRunningAutoLogin;


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
        //回调
        _sharedSingleton.messageListeners=[[NSMutableDictionary alloc] init];
        //会话的监听
        _sharedSingleton.sessionListeners=[[NSMutableArray alloc]init];
        //还没有被初始化
        _sharedSingleton.isSetup=false;
    });
    return _sharedSingleton;
}

//重设用户名和密码
-(void)resetServer:(NSString*)serverUrl
      andUploadUrl:(NSString*)upload{
    [[FlappyApiConfig shareInstance] resetServer:serverUrl
                                    andUploadUrl:upload];
}

//增加本地通知
-(void)initLocalNotification{
    //后台了，但是还没有被墓碑的情况
    //__weak typeof(self) safeSelf=self;
    [self addGloableMsgListener:[[FlappyMessageListener alloc]
                                 initWithSend:^(ChatMessage * _Nullable message) {
        
    } andFailure:^(ChatMessage * _Nullable message) {
        
    } andReceiveList:^(NSArray * _Nullable messageList) {
        
    } andReceive:^(ChatMessage * _Nullable message) {
        //判断当前是在后台还是前台，如果是在后台，那么
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        //如果再后台
        if(state == UIApplicationStateBackground || state == UIApplicationStateInactive){
            //判断当前是在后台还是在前台
            //[safeSelf sendLocalNotification:message];
        }
    } andDelete:^(ChatMessage * _Nullable message) {
        
    } andReadOther:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    } andReadSelf:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    }]];
}

//获取唯一的ID
+(NSString*)getPushId{
    return [[FlappyData shareInstance] getPushId];
}


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored"-Wdeprecated-declarations"


//注册远程推送和本地消息通知
-(void)registerRemoteNotice:(UIApplication *)application{
    //iOS8以上 注册APNs
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
        UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge |
        UIUserNotificationTypeSound |
        UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    //以下注册APNS
    else{
        UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeSound |
        UIRemoteNotificationTypeAlert;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    }
    
    //注册本地通知
    if (@available(iOS 11.0, *))
    {
        // 使用 UNUserNotificationCenter 来管理通知
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        //监听回调事件
        center.delegate = self;
        //iOS 10 使用以下方法注册，才能得到授权，注册通知以后，会自动注册 deviceToken，如果获取不到 deviceToken，Xcode8下要注意开启 Capability->Push Notification。
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound+ UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            // Enable or disable features based on authorization.
            if (!granted)
            {
                NSLog(@"Xcode8下要注意开启 Capability->Push Notification。");
            }
        }];
        
        //获取当前的通知设置，UNNotificationSettings 是只读对象，不能直接修改，只能通过以下方法获取
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            
        }];
    }
    else {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

#pragma GCC diagnostic pop


//监听到本地的通知
-(void)didReceiveRemoteNotification:(NSDictionary *)userInfo{
    if(userInfo!=nil&&userInfo[@"message"]!=nil){
        if(self.notifyClicked!=nil){
            //获取消息
            NSString* msg=userInfo[@"message"];
            //转换为消息体
            self.notifyClicked([ChatMessage mj_objectWithKeyValues:[FlappyJsonTool JSONStringToDictionary:msg]]);
            //移除
            UNRemoveObject(@"flappy_message");
        }else{
            //获取消息
            NSString* msg=userInfo[@"message"];
            //保存本地
            UNSaveObject(msg,@"flappy_message");
        }
    }
}

//注册
-(void)registerDeviceToken:(NSData *)deviceToken{
    NSMutableString *deviceTokenStr = [NSMutableString string];
    //Xcode11打的包，iOS13获取Token有变化
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 13) {
        const char *bytes = deviceToken.bytes;
        long iCount = deviceToken.length;
        for (long i = 0; i < iCount; i++) {
            [deviceTokenStr appendFormat:@"%02x", bytes[i]&0x000000FF];
        }
    } else {
        NSString *token = [NSString stringWithFormat:@"%@",deviceToken];
        token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
        token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
        token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
        deviceTokenStr=[NSMutableString stringWithFormat:@"%@",token];
    }
    
    //保存推送ID
    [[FlappyData shareInstance] savePushId: deviceTokenStr];
    
    //更新字符串
    [self updateDeviceToken:deviceTokenStr];
}

//更新设备token
-(void)updateDeviceToken:(NSString*)deviceTokenStr{
    
    //用户为空或者没有登录
    if([[FlappyData shareInstance] getUser]==nil||[[FlappyData shareInstance] getUser].login==false){
        return;
    }
    
    //设置的推送ID相等
    if([[FlappyData shareInstance] getPushId]!=nil&&[[[FlappyData shareInstance] getPushId] isEqualToString:deviceTokenStr]){
        return;
    }
    
    //循环引用
    __weak typeof(self) safeSelf=self;
    [self changePushType:nil
             andPushPlat:nil
               andPushId:deviceTokenStr
             andLanguage:nil
              andPrivacy:nil
                 andMute:nil
              andSuccess:nil
              andFailure:^(NSError * error, NSInteger code) {
        [NSObject cancelPreviousPerformRequestsWithTarget:safeSelf
                                                 selector:@selector(updateDeviceToken:)
                                                   object:deviceTokenStr];
        //修改失败
        [safeSelf performSelector:@selector(updateDeviceToken:)
                       withObject:deviceTokenStr
                       afterDelay:[FlappyApiConfig shareInstance].autoLoginInterval];
    }];
}


///修改推送
-(void)changePushType:(nullable NSString*)pushType
          andPushPlat:(nullable NSString*)pushPlat
            andPushId:(nullable NSString*)pushId
          andLanguage:(nullable NSString*)pushLanguage
           andPrivacy:(nullable NSString*)pushPrivacy
              andMute:(nullable NSString*)pushMute
           andSuccess:(nullable FlappySuccess)success
           andFailure:(nullable FlappyFailure)failure{
    
    //没有登录的状态
    if([[FlappyData shareInstance] getUser]==nil&&[[FlappyData shareInstance] getUser].login==false){
        //保存推送的基本信息
        PushSettings* settings=[[PushSettings alloc] init];
        settings.routePushType = pushType;
        settings.routePushPlat = pushPlat;
        settings.routePushId = pushId;
        settings.routePushLanguage = pushLanguage;
        settings.routePushPrivacy = pushPrivacy;
        settings.routePushMute = pushMute;
        [[FlappyData shareInstance] savePushSetting:settings];
        if(success!=nil){
            success([[FlappyData shareInstance] getPushSetting]);
        }
        return;
    }
    
    //已经登录的状态
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[FlappyData shareInstance]getUser].userExtendId forKey:@"userExtendId"];
    [parameters setObject:DEVICE_PLAT forKey:@"devicePlat"];
    [parameters setObject:[[FlappyData shareInstance] getDeviceId] forKey:@"deviceId"];
    if (pushType) [parameters setObject:pushType forKey:@"pushType"];
    if (pushPlat) [parameters setObject:pushPlat forKey:@"pushPlat"];
    if (pushId) [parameters setObject:pushId forKey:@"pushId"];
    if (pushLanguage) [parameters setObject:pushLanguage forKey:@"pushLanguage"];
    if (pushPrivacy) [parameters setObject:pushPrivacy forKey:@"pushPrivacy"];
    if (pushMute) [parameters setObject:pushMute forKey:@"pushMute"];
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_changePush;
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        PushSettings* settings = [PushSettings mj_objectWithKeyValues:data];
        [[FlappyData shareInstance] savePushSetting:settings];
        if(success!=nil){
            success([[FlappyData shareInstance] getPushSetting]);
        }
    } withFailure:^(NSError * error, NSInteger code) {
        //失败
        if(failure!=nil){
            failure(error,code);
        }
    }];
}

//获取当前的推送设置
-(PushSettings*)getPushSettings{
    return   [[FlappyData shareInstance] getPushSetting];
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
    ChatUser* user=[[FlappyData shareInstance]getUser];
    //用户存在，但是登录状态不对，代表已经被踢下线了
    if(user!=nil&&user.login==false){
        if(self.knicked!=nil){
            self.knicked();
        }
    }
}

//收到点击事件时候的通知
-(void)setNotifyClickListener:(__nullable NotifyClickListener)clicked{
    //保留
    _notifyClicked=clicked;
    //消息
    NSString* message=UNGetObject(@"flappy_message");
    //消息
    if(message!=nil){
        //转换为消息体
        _notifyClicked([ChatMessage mj_objectWithKeyValues:[FlappyJsonTool JSONStringToDictionary:message]]);
        //移除
        UNRemoveObject(@"flappy_message");
    }
}


//初始化
-(void)setup{
    if(!self.isSetup){
        //初始化数据库
        [self setupDataBase];
        //通知
        [self setupNotify];
        //重新连接
        [self autoLogin];
        //当前是活跃的
        self.isForground=true;
    }
}


//初始化
-(void)setup:(NSString*)serverUrl  withUploadUrl:(NSString*)uploadUrl{
    //重新设置服务器地址
    [[FlappyApiConfig shareInstance] resetServer:serverUrl andUploadUrl:uploadUrl];
    if(!self.isSetup){
        //初始化数据库
        [self setupDataBase];
        //通知
        [self setupNotify];
        //重新连接
        [self autoLogin];
        //当前是活跃的
        self.isForground=true;
    }
}

//设置推送类型
-(void)setPushType:(NSString*)pushType{
    [[FlappyData shareInstance] savePushType:pushType];
}

//设置推送平台
-(void)setPushPlat:(NSString*)pushPlat{
    [[FlappyData shareInstance] savePushPlat:pushPlat];
}

//设置RSA public key
-(void)setRsaPublicKey:(NSString*)key{
    [[FlappyData shareInstance] saveRsaKey:key];
}

//获取RSA public key
-(NSString*)getRsaPublicKey{
    return [[FlappyData shareInstance] getRsaKey];
}

//增加消息的监听
-(void)addGloableMsgListener:(FlappyMessageListener*)listener{
    //监听所有消息
    if(listener!=nil){
        NSMutableArray* listeners=[self.messageListeners objectForKey:GlobalKey];
        if(listeners==nil){
            listeners=[[NSMutableArray alloc]init];
            [self.messageListeners setObject:listeners forKey:GlobalKey];
        }
        [listeners addObject:listener];
    }
}

//移除监听
-(void)removeGloableMsgListener:(FlappyMessageListener*)listener{
    //监听所有消息
    if(listener!=nil){
        NSMutableArray* listeners=[self.messageListeners objectForKey:GlobalKey];
        if(listeners!=nil){
            [listeners removeObject:listener];
        }
    }
}

//增加某个session的监听
-(void)addMsgListener:(FlappyMessageListener*)listener
        withSessionID:(NSString*)sessionID{
    //监听所有消息
    if(listener!=nil){
        NSMutableArray* listeners=[self.messageListeners objectForKey:sessionID];
        if(listeners==nil){
            listeners=[[NSMutableArray alloc]init];
            [self.messageListeners setObject:listeners forKey:sessionID];
        }
        [listeners addObject:listener];
    }
}

//移除会话的
-(void)removeMsgListener:(FlappyMessageListener*)listener
           withSessionID:(NSString*)sessionID{
    //监听所有消息
    if(listener!=nil){
        NSMutableArray* listeners=[self.messageListeners objectForKey:sessionID];
        if(listeners!=nil){
            [listeners removeObject:listener];
        }
    }
}

//新增会话监听
-(void)addSessionListener:(FlappySessionListener*)listener{
    [self.sessionListeners addObject:listener];
}

//移除会话监听
-(void)removeSessionListener:(FlappySessionListener*)listener{
    [self.sessionListeners removeObject:listener];
}


#pragma database
-(void)setupDataBase{
    //初始化数据库
    [[FlappyDataBase shareInstance] setup];
    //清空消息
    [[FlappyDataBase shareInstance] clearSendingMessage];
}

#pragma  NOTIFY 网络状态监听通知
-(void)setupNotify{
    //监听网络状态变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kFlappyReachabilityChangedNotification
                                               object:nil];
    // 设置网络检测的站点
    NSString *remoteHostName = @"www.baidu.com";
    self.hostReachability = [FlappyReachability reachabilityWithHostName:remoteHostName];
    [self.hostReachability startNotifier];
    [self updateInterfaceWithReachability:self.hostReachability];
    
    //监听是否触发home键挂起程序，（把程序放在后台执行其他操作）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    //监听是否重新进入程序程序.（回到程序)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

//监听被home键盘
-(void)applicationWillResignActive:(NSNotification *)notification{
    self.isForground=false;
    if(self.flappysocket!=nil){
        [self.flappysocket offline:true];
        self.flappysocket=nil;
        NSLog(@"后台下线");
    }
}

//监听进入页面
-(void)applicationDidBecomeActive:(NSNotification *)notification{
    self.isForground=true;
    [self autoLogin];
}

//变化监听
- (void) reachabilityChanged:(NSNotification *)note
{
    [self updateInterfaceWithReachability:[note object]];
}

//更新网络状态
- (void)updateInterfaceWithReachability:(FlappyReachability *)reachability
{
    
    FlappyNetworkStatus netStatus = [reachability currentReachabilityStatus];
    switch (netStatus) {
        case 0:
            break;
        case 1:
        case 2:
            [self autoLogin];
            break;
        default:
            break;
    }
}

//停止监听
-(void)stopOberver{
    //移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kFlappyReachabilityChangedNotification
                                                  object:nil];
    
    
    //移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    
    //移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    
}




//创建账号
-(void)createAccount:(NSString*)userExtendId
         andUserName:(NSString*)userName
       andUserAvatar:(NSString*)userAvatar
         andUserData:(NSString*)userData
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure{
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_register;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendId":userExtendId,
                                 @"userName":userName,
                                 @"userData":userData,
                                 @"userAvatar":userAvatar
    };
    
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:success
                      withFailure:failure];
    
}


//创建账号
-(void)updateAccount:(NSString*)userExtendId
         andUserName:(NSString*)userName
       andUserAvatar:(NSString*)userAvatar
         andUserData:(NSString*)userData
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure{
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_update;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendId":userExtendId,
                                 @"userName":userName,
                                 @"userData":userData,
                                 @"userAvatar":userAvatar
    };
    
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:success
                      withFailure:failure];
    
}


//登录账号
-(void)login:(NSString*)userExtendId
  andSuccess:(FlappySuccess)success
  andFailure:(FlappyFailure)failure{
    
    @synchronized(FlappyIM.class){
        
        //如果当前正在登录，那么直接失败，否则就设置为正在登录状态
        if(self.isRunningLogin){
            failure([NSError errorWithDomain:@"A login thread also run"
                                        code:RESULT_NETERROR
                                    userInfo:nil],RESULT_NETERROR);
            return ;
        }
        
        //如果当前有正在连接的socket,之前的正常下线
        self.isRunningLogin=true;
        
        //构建注册请求参数
        NSString *urlString = [FlappyApiConfig shareInstance].URL_login;
        NSDictionary *parameters = @{
            @"userExtendId":userExtendId,
            @"devicePlat":DEVICE_PLAT,
            @"deviceId":[[FlappyData shareInstance] getDeviceId],
            @"pushType":[[FlappyData shareInstance] getPushType],
            @"pushPlat":[[FlappyData shareInstance] getPushPlat],
            @"pushId":[[FlappyData shareInstance] getPushId],
        };
        
        //http做登录处理
        __weak typeof(self) safeSelf=self;
        [FlappyApiRequest postRequest:urlString
                       withParameters:parameters
                          withSuccess:^(id data) {
            
            //http登录完成之后登录netty
            [safeSelf loginNetty:data
                      andSuccess:success
                      andFailure:failure];
            
        } withFailure:^(NSError * error, NSInteger code) {
            failure(error,code);
            safeSelf.isRunningLogin=false;
        }];
    }
}




//登录netty
-(void)loginNetty:(id)data
       andSuccess:(FlappySuccess)success
       andFailure:(FlappyFailure)failure{
    
    @synchronized (FlappyIM.class) {
        
        //如果之前的还存在，那么之前的就下线
        if(self.flappysocket!=nil){
            [self.flappysocket offline:true];
            self.flappysocket=nil;
        }
        
        //得到当前的用户数据
        NSDictionary* dic=data[@"user"];
        //用户
        ChatUser* user=[ChatUser mj_objectWithKeyValues:dic];
        //登录成功
        user.login=true;
        
        //创建socket
        __weak typeof(self) safeSelf=self;
        
        //登录失败
        FlappyFailureWrap* failureWrap= [[FlappyFailureWrap alloc] initWithFailure:^(NSError *error,NSInteger code){
            failure(error,code);
            safeSelf.isRunningLogin=false;
        }];
        
        //开始链接
        self.flappysocket=[[FlappySocket alloc] initWithSuccess:^(id sdata) {
            [safeSelf savePushData:data];
            success(sdata);
            safeSelf.isRunningLogin=false;
        }
                                                     andFailure:failureWrap
                                                        andDead:^{
            //如果socket非正常死亡，那么就跳转进入自动重连模式
            [safeSelf performSelector:@selector(autoLogin)
                           withObject:nil
                           afterDelay:[FlappyApiConfig shareInstance].autoLoginInterval];
        }];
        //登录数据
        self.flappysocket.loginData=data;
        //连接服务器
        [self.flappysocket connectSocket:data[@"serverIP"]
                                withPort:data[@"serverPort"]
                                withUser:user];
    }
    
}



//进行初始化
-(void)autoLogin{
    @synchronized (FlappyIM.class) {
        
        //当前用户没有登录或者被踢下线的情况
        ChatUser* user=[[FlappyData shareInstance] getUser];
        if(user==nil || user.login==false){
            return;
        }
        
        //如果正在登录,那么延后执行
        if(self.isRunningLogin){
            return;
        }
        
        //如果正在自动登录,那么不执行
        if(self.isRunningAutoLogin){
            return;
        }
        
        //当前是已经连接的，不需要继续登录了
        if([self isOnline]){
            return;
        }
        
        //网络不可达或者当前不在前台
        if([_hostReachability currentReachabilityStatus] == FlappyNotReachable||!self.isForground){
            return;
        }
        
        //是否正在登录
        self.isRunningAutoLogin=true;
        
        
        //自动登录
        NSString *urlString = [FlappyApiConfig shareInstance].URL_autoLogin;
        NSDictionary *parameters = @{@"userId":[[FlappyData shareInstance] getUser].userId,
                                     @"devicePlat":DEVICE_PLAT,
                                     @"deviceId":[[FlappyData shareInstance] getDeviceId],
                                     @"pushType":[[FlappyData shareInstance] getPushType],
                                     @"pushPlat":[[FlappyData shareInstance] getPushPlat],
                                     @"pushId":[[FlappyData shareInstance] getPushId],
        };
        
        __weak typeof(self) safeSelf=self;
        [FlappyApiRequest postRequest:urlString
                       withParameters:parameters
                          withSuccess:^(id data) {
            
            safeSelf.isRunningAutoLogin=false;
            [safeSelf autoLoginNetty:data];
            
        } withFailure:^(NSError * error, NSInteger code) {
            
            safeSelf.isRunningAutoLogin=false;
            if(code==RESULT_KNICKED){
                ChatUser* uesr=[[FlappyData shareInstance]getUser];
                uesr.login=false;
                [[FlappyData shareInstance]saveUser:uesr];
                if(safeSelf.knicked!=nil){
                    safeSelf.knicked();
                    safeSelf.knicked=nil;
                }
            }else{
                [safeSelf performSelector:@selector(autoLogin)
                               withObject:nil
                               afterDelay:[FlappyApiConfig shareInstance].autoLoginInterval];
            }
        }];
        
    }
}


//自动登录netty
-(void)autoLoginNetty:(id)data{
    @synchronized (FlappyIM.class) {
        
        
        //得到当前的用户数据
        NSDictionary* dic=data[@"user"];
        //用户
        ChatUser* newUser=[ChatUser mj_objectWithKeyValues:dic];
        
        //当前用户没有登录或者被踢下线的情况
        ChatUser* formerUser=[[FlappyData shareInstance] getUser];
        if(formerUser==nil || formerUser.login==false){
            return;
        }
        
        //用户不一致，那么也不行
        if (![formerUser.userId isEqualToString: newUser.userId]) {
            return;
        }
        
        //如果正在登录,那么延后执行
        if(self.isRunningLogin){
            return;
        }
        
        //如果正在自动登录,那么不执行
        if(self.isRunningAutoLogin){
            return;
        }
        
        //当前是已经连接的，不需要继续登录了
        if([self isOnline]){
            return;
        }
        
        //网络不可达或者当前不在前台
        if([_hostReachability currentReachabilityStatus] == FlappyNotReachable||!self.isForground){
            return;
        }
        
        //正在自动登录
        self.isRunningAutoLogin=true;
        
        //保存数据
        [formerUser setLogin:1];
        formerUser.userAvatar=newUser.userAvatar;
        formerUser.userName=newUser.userName;
        formerUser.userData=newUser.userData;
        [[FlappyData shareInstance] saveUser:formerUser];
        
        //如果当前有正在连接的socket,先下线了
        if(self.flappysocket!=nil){
            [self.flappysocket offline:true];
            self.flappysocket=nil;
        }
        
        //当前的
        __weak typeof(self) safeSelf=self;
        //创建新的socket
        self.flappysocket=[[FlappySocket alloc] initWithSuccess:^(id sdata) {
            [safeSelf savePushData:data];
            safeSelf.isRunningAutoLogin=false;
        }
                                                     andFailure:[[FlappyFailureWrap alloc] initWithFailure:^(NSError *error,NSInteger code){
            safeSelf.isRunningAutoLogin=false;
        }]
                                                        andDead:^{
            [safeSelf performSelector:@selector(autoLogin)
                           withObject:nil
                           afterDelay:[FlappyApiConfig shareInstance].autoLoginInterval];
        }];
        
        //设置登录返回的数据
        self.flappysocket.loginData=data;
        //连接服务器
        [self.flappysocket connectSocket:data[@"serverIP"]
                                withPort:data[@"serverPort"]
                                withUser:newUser];
        
    }
}


//退出登录下线
-(void)logout:(FlappySuccess)success
   andFailure:(FlappyFailure)failure{
    
    //加锁当前的
    @synchronized (self) {
        //为空直接出错
        if([[FlappyData shareInstance] getUser] == nil){
            failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
            return ;
        }
        
        //正在登录
        if(self.isRunningLogin){
            failure([NSError errorWithDomain:@"Other thread is running login" code:0 userInfo:nil],RESULT_NOTLOGIN);
            return ;
        }
        
        //注册地址
        //请求体，参数（NSDictionary 类型）
        NSString *urlString = [FlappyApiConfig shareInstance].URL_logout;
        NSDictionary *parameters = @{@"userExtendId":[[FlappyData shareInstance]getUser].userExtendId,
                                     @"devicePlat":DEVICE_PLAT,
                                     @"deviceId":[[FlappyData shareInstance] getDeviceId]
        };
        //请求数据
        __weak typeof(self) safeSelf = self;
        [FlappyApiRequest postRequest:urlString
                       withParameters:parameters
                          withSuccess:^(id data) {
            //退出登录成功
            success(data);
            [safeSelf logoutNetty];
        } withFailure:^(NSError * error, NSInteger code) {
            //登录失败，清空回调
            failure(error,code);
        }];
    }
}

//logout netty
-(void)logoutNetty{
    @synchronized (FlappyIM.class) {
        //之前的正常下线
        if(self.flappysocket!=nil){
            [self.flappysocket offline:true];
            self.flappysocket=nil;
        }
        [[FlappyData shareInstance] clearUser];
    }
}

//保存推送类型
-(void)savePushData:(id)data{
    //保存推送类型
    @try {
        PushSettings* settings=[PushSettings mj_objectWithKeyValues:data[@"route"]];
        [[FlappyData shareInstance] savePushSetting:settings];
    } @catch (NSException *exception) {
        //打印错误日志
        NSLog(@"FlappyIM:%@",exception.description);
    }
}

//创建两个人的会话
-(void)createSingleSessionByPeer:(NSString*)peerExtendId
                      andSuccess:(FlappySuccess)success
                      andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([[FlappyData shareInstance] getUser]==nil){
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_createSingleSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userOne":[[FlappyData shareInstance]getUser].userExtendId,
                                 @"userTwo":peerExtendId,
    };
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        ChatSessionData* model=[ChatSessionData mj_objectWithKeyValues:data];
        //创建session
        FlappyChatSession* session=[FlappyChatSession mj_objectWithKeyValues:data];
        session.session=model;
        success(session);
    } withFailure:^(NSError * error, NSInteger code) {
        //登录失败，清空回调
        failure(error,code);
    }];
}

//获取单聊的会话
-(void)getSingleSessionByPeer:(NSString*)peerExtendId
                   andSuccess:(FlappySuccess)success
                   andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([[FlappyData shareInstance] getUser]==nil){
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //创建
    NSMutableArray* array=[[NSMutableArray alloc]init];
    [array addObject:peerExtendId];
    [array addObject:[FlappyData shareInstance].getUser.userExtendId];
    NSArray *newArray = [array sortedArrayUsingComparator:^(NSString * obj1, NSString * obj2){
        return (NSComparisonResult)[obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接
    NSString* sessionExtendId=[NSString stringWithFormat:@"%@-%@",newArray[0],newArray[1]];
    //获取当前用户下，当前的会话
    ChatSessionData* data=[[FlappyDataBase shareInstance] getUserSessionByExtendId:sessionExtendId];
    if(data!=nil){
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=data;
        success(session);
    }else{
        [self getSingleSessionByPeerHttp:peerExtendId
                              andSuccess:success
                              andFailure:failure];
    }
}

//网络获取单聊用户的会话，没有就会创建
-(void)getSingleSessionByPeerHttp:(NSString*)peerExtendId
                       andSuccess:(FlappySuccess)success
                       andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getSingleSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userOne":[[FlappyData shareInstance]getUser].userExtendId,
                                 @"userTwo":peerExtendId,
    };
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        ChatSessionData* model=[ChatSessionData mj_objectWithKeyValues:data];
        //创建session
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=model;
        success(session);
    } withFailure:^(NSError * error, NSInteger code) {
        //登录失败，清空回调
        failure(error,code);
    }];
}




//创建群组会话
-(void)createGroupSession:(NSArray*)userExtendIds
      withSessionExtendId:(NSString*)sessionExtendId
          withSessionName:(NSString*)sessionName
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //转换为data
    NSData *usersData=[NSJSONSerialization dataWithJSONObject:userExtendIds
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:nil];
    //转换为字符串
    NSString *jsonStr=[[NSString alloc]initWithData:usersData
                                           encoding:NSUTF8StringEncoding];
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_createGroupSession;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendIds":jsonStr,
                                 @"createUserId":[[FlappyData shareInstance]getUser].userId,
                                 @"sessionExtendId":sessionExtendId,
                                 @"sessionName":sessionName
    };
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        ChatSessionData* model=[ChatSessionData mj_objectWithKeyValues:data];
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=model;
        success(session);
    } withFailure:^(NSError * error, NSInteger code) {
        //登录失败，清空回调
        failure(error,code);
    }];
    
}


//通过sessionID获取
-(void)getSessionById:(NSString*)sessionId
           andSuccess:(FlappySuccess)success
           andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //获取当前用户下，当前的会话
    ChatSessionData* data=[[FlappyDataBase shareInstance] getUserSessionByID:sessionId];
    //成功
    if(data!=nil){
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=data;
        success(session);
    }else{
        //获取用户会话
        [self getSessionByIdHttp:sessionId
                      andSuccess:success
                      andFailure:failure];
    }
}


//获取会话ID
-(void)getSessionByIdHttp:(NSString*)sessionId
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getSessionById;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"sessionId":sessionId};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        ChatSessionData* model=[ChatSessionData mj_objectWithKeyValues:data];
        //创建session
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        //数据
        session.session=model;
        //成功
        success(session);
    } withFailure:^(NSError * error, NSInteger code) {
        //登录失败，清空回调
        failure(error,code);
    }];
}

//通过extendID获取
-(void)getSessionByExtendId:(NSString*)sessionExtendId
                 andSuccess:(FlappySuccess)success
                 andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //获取当前用户下，当前的会话
    ChatSessionData* data=[[FlappyDataBase shareInstance] getUserSessionByExtendId:sessionExtendId];
    //成功
    if(data!=nil){
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=data;
        success(session);
    }else{
        //获取用户会话
        [self getSessionByExtendIdHttp:sessionExtendId
                            andSuccess:success
                            andFailure:failure];
    }
}

//通过获取会话
-(void)getSessionByExtendIdHttp:(NSString*)sessionExtendId
                     andSuccess:(FlappySuccess)success
                     andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getSessionByExtendId;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"sessionExtendId":sessionExtendId};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        ChatSessionData* model=[ChatSessionData mj_objectWithKeyValues:data];
        //创建session
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        //数据
        session.session=model;
        //成功
        success(session);
    } withFailure:^(NSError * error, NSInteger code) {
        //登录失败，清空回调
        failure(error,code);
    }];
}

//获取用户会话列表
-(void)getUserSessionList:(FlappySuccess)success
               andFailure:(FlappyFailure)failure {
    //为空直接出错
    if ([[FlappyData shareInstance] getUser] == nil) {
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil], RESULT_NOTLOGIN);
        return;
    }
    
    //创建返回
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    //获取当前用户的所有
    NSMutableArray *array = [[FlappyDataBase shareInstance] getUserSessions:[FlappyData shareInstance].getUser.userExtendId];
    
    // 创建一个字典来缓存每个会话的最新消息
    NSMutableDictionary *latestMessagesCache = [NSMutableDictionary dictionary];
    
    for (int s = 0; s < array.count; s++) {
        //获取model
        ChatSessionData *model = [ChatSessionData mj_objectWithKeyValues:[array objectAtIndex:s]];
        FlappyChatSession *session = [[FlappyChatSession alloc] init];
        session.session = model;
        [ret addObject:session];
        
        //获取最新消息并缓存
        ChatMessage *latestMessage = [session getLatestMessage];
        if (latestMessage) {
            latestMessagesCache[session.session.sessionId] = latestMessage;
        }
    }
    
    //进行一个排序
    NSArray *sortArray = [ret sortedArrayUsingComparator:^NSComparisonResult(FlappyChatSession *_Nonnull one,
                                                                             FlappyChatSession *_Nonnull two) {
        if (one.session.sessionType == TYPE_SYSTEM) {
            return NSOrderedAscending;
        }
        if (two.session.sessionType == TYPE_SYSTEM) {
            return NSOrderedDescending;
        }
        //从缓存中获取最新消息
        ChatMessage *msgOne = latestMessagesCache[one.session.sessionId];
        ChatMessage *msgTwo = latestMessagesCache[two.session.sessionId];
        if (msgOne == nil) {
            return NSOrderedDescending;
        }
        if (msgTwo == nil) {
            return NSOrderedAscending;
        }
        if (msgOne.messageTableOffset > msgTwo.messageTableOffset) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    ret = [[NSMutableArray alloc] initWithArray:sortArray];
    
    //成功
    if (ret != nil && ret.count != 0) {
        success(ret);
    } else {
        //没有拿到就联网去拿
        [self getUserSessionListHttp:success andFailure:failure];
    }
}

//获取用户会话列表
-(void)getUserSessionListHttp:(FlappySuccess)success
                   andFailure:(FlappyFailure)failure {
    
    //为空直接出错
    if ([[FlappyData shareInstance] getUser] == nil) {
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil], RESULT_NOTLOGIN);
        return;
    }
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getUserSessionList;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendId": [[FlappyData shareInstance] getUser].userExtendId};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        NSMutableArray *array = data;
        NSMutableArray *ret = [[NSMutableArray alloc] init];
        // 创建一个字典来缓存每个会话的最新消息
        NSMutableDictionary *latestMessagesCache = [NSMutableDictionary dictionary];
        
        for (int s = 0; s < array.count; s++) {
            //获取model
            ChatSessionData *model = [ChatSessionData mj_objectWithKeyValues:[array objectAtIndex:s]];
            FlappyChatSession *session = [[FlappyChatSession alloc] init];
            session.session = model;
            [ret addObject:session];
            
            // 获取最新消息并缓存
            ChatMessage *latestMessage = [session getLatestMessage];
            if (latestMessage) {
                latestMessagesCache[session.session.sessionId] = latestMessage;
            }
        }
        //进行一个排序
        NSArray *sortArray = [ret sortedArrayUsingComparator:^NSComparisonResult(FlappyChatSession *_Nonnull one,
                                                                                 FlappyChatSession *_Nonnull two) {
            if (one.session.sessionType == TYPE_SYSTEM) {
                return NSOrderedAscending;
            }
            if (two.session.sessionType == TYPE_SYSTEM) {
                return NSOrderedDescending;
            }
            // 从缓存中获取最新消息
            ChatMessage *msgOne = latestMessagesCache[one.session.sessionId];
            ChatMessage *msgTwo = latestMessagesCache[two.session.sessionId];
            if (msgOne == nil) {
                return NSOrderedDescending;
            }
            if (msgTwo == nil) {
                return NSOrderedAscending;
            }
            if (msgOne.messageTableOffset > msgTwo.messageTableOffset) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        }];
        ret = [[NSMutableArray alloc] initWithArray:sortArray];
        //成功
        success(ret);
    } withFailure:^(NSError *error, NSInteger code) {
        //登录失败，清空回调
        failure(error, code);
    }];
}


//添加用户到群组
-(void)addUserToSession:(NSString*)userExtendId
            withGroupID:(NSString*)sessionExtendId
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_addUserToSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"sessionExtendId":sessionExtendId,
                                 @"userExtendId":userExtendId};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        ChatSessionData* model=[ChatSessionData mj_objectWithKeyValues:data];
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
-(void)delUserInSession:(NSString*)userExtendId
            withGroupID:(NSString*)sessionExtendId
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_delUserInSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"sessionExtendId":sessionExtendId,
                                 @"userExtendId":userExtendId};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        ChatSessionData* model=[ChatSessionData mj_objectWithKeyValues:data];
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

//搜索文本消息
-(NSMutableArray *)searchTextMessage:(NSString*)text
                        andSessionId:(NSString*)sessionId
                        andMessageId:(NSString*)messageId
                             andSize:(NSInteger)size{
    return [[FlappyDataBase shareInstance] searchTextMessage:text
                                                andSessionId:sessionId
                                                andMessageId:messageId
                                                     andSize:size];
}


//搜索图片消息
-(NSMutableArray *)searchImageMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size{
    
    return [[FlappyDataBase shareInstance] searchImageMessage:sessionId
                                                 andMessageId:messageId
                                                      andSize:size];
}

//搜索消息之前的视频消息
-(NSMutableArray *)searchVideoMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size{
    
    return [[FlappyDataBase shareInstance] searchVideoMessage:sessionId
                                                 andMessageId:messageId
                                                      andSize:size];
}

//搜索消息之前的语音消息
-(NSMutableArray *)searchVoiceMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size{
    
    return [[FlappyDataBase shareInstance] searchVoiceMessage:sessionId
                                                 andMessageId:messageId
                                                      andSize:size];
}

//判断当前是否在线
-(Boolean)isOnline{
    if(self.flappysocket!=nil&&self.flappysocket.isActive){
        return true;
    }
    return false;
}


//判断当前用户是否登录
-(Boolean)isLogin{
    //获取当前账户
    ChatUser* user=[[FlappyData shareInstance]getUser];
    //如果当前账户不是登录的状态
    if(user==nil||user.login==false){
        return false;
    }
    //返回状态
    return true;
}

//获取登录信息
-(ChatUser*)getLoginInfo{
    //获取当前账户
    ChatUser* user=[[FlappyData shareInstance]getUser];
    //获取当前账户
    return user;
}

#pragma  dealloc
//销毁逻辑
-(void)dealloc{
    //下线
    [self.flappysocket  offline:true];
    //停止
    [self stopOberver];
    //清空
    [self.messageListeners removeAllObjects];
}


//IOS 10以上预处理
#pragma mark - UNUserNotificationCenterDelegate
//在展示通知前进行处理，即有机会在展示通知前再修改通知内容。
-(void)userNotificationCenter:(UNUserNotificationCenter *)center
      willPresentNotification:(UNNotification *)notification
        withCompletionHandler:(void(^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10.0)){
    //1. 处理通知
    //2. 处理完成后条用 completionHandler ，用于指示在前台显示通知的形式
    completionHandler(UNNotificationPresentationOptionAlert+UNNotificationPresentationOptionSound+UNNotificationPresentationOptionBadge);
}


// 通知的点击事件
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler API_AVAILABLE(ios(10.0)){
    //用户推送的信息
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    // 收到推送的请求
    //UNNotificationRequest *request = response.notification.request;
    // 收到推送的消息内容
    //UNNotificationContent *content = request.content;
    // 推送消息的角标
    //NSNumber *badge = content.badge;
    // 推送消息体
    //NSString *body = content.body;
    // 推送消息的声音
    //UNNotificationSound *sound = content.sound;
    // 推送消息的副标题
    //NSString *subtitle = content.subtitle;
    // 推送消息的标题
    //NSString *title = content.title;
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //远程通知
        [self didReceiveRemoteNotification:userInfo];
    }
    else {
        //本地通知
        [self didReceiveRemoteNotification:userInfo];
    }
    // Warning: UNUserNotificationCenter delegate received call to -userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: but the completion handler was never called.
    // 系统要求执行这个方法
    completionHandler();
    
}


@end
