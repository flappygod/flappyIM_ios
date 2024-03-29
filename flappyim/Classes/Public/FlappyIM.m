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
        //设置一个唯一的UUID
        _sharedSingleton.pushID=[FlappyIM getUUID];
        //回调
        _sharedSingleton.messageListeners=[[NSMutableDictionary alloc] init];
        //会话的监听
        _sharedSingleton.sessionListeners=[[NSMutableArray alloc]init];
        //还没有被初始化
        _sharedSingleton.isSetup=false;
        //不再使用本地推送了
        //[_sharedSingleton initLocalNotification];
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
    __weak typeof(self) safeSelf=self;
    [self addGloableMsgListener:[[FlappyMessageListener alloc]
                                 initWithSend:^(ChatMessage * _Nullable message) {
        
    } andFailure:^(ChatMessage * _Nullable message) {
        
    } andUpdate:^(ChatMessage * _Nullable message) {
        
    } andReceive:^(ChatMessage * _Nullable message) {
        //判断当前是在后台还是前台，如果是在后台，那么
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        //如果再后台
        if(state == UIApplicationStateBackground || state == UIApplicationStateInactive){
            //判断当前是在后台还是在前台
            [safeSelf sendLocalNotification:message];
        }
    } andRead:^(NSString * _Nullable tableSeqence) {
        
    } andDelete:^(NSString * _Nullable messageId) {
        
    }]];
}

//获取唯一的ID
+(NSString*)getUUID{
    NSString* former=[[FlappyData shareInstance]getPush];
    if([FlappyStringTool isStringEmpty:former]){
        NSString* UUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [[FlappyData shareInstance]savePush:UUID];
    }
    return [[FlappyData shareInstance]getPush];
}

//设备的token
-(void)setUUID:(NSString*)token{
    //设置
    [[FlappyData shareInstance]savePush:token];
    //获取唯一的推送ID
    self.pushID=token;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored"-Wdeprecated-declarations"

//发送本地通知
- (void)sendLocalNotification:(ChatMessage*)msg{
    //标题
    NSString *title = @"消息提醒";
    //新的信息
    NSString *body =  @"您有一条新的信息";
    //消息类型
    if(msg.messageType==MSG_TYPE_TEXT){
        //邓肯
        NSInteger pushTy=[FlappyStringTool toUnNullZeroStr:[[FlappyData shareInstance]getPushType]].integerValue;
        //普通
        if(pushTy==0){
            body=[msg getChatText];
        }
    }
    else if(msg.messageType==MSG_TYPE_IMG){
        //邓肯
        NSInteger pushTy=[FlappyStringTool toUnNullZeroStr:[[FlappyData shareInstance]getPushType]].integerValue;
        //普通
        if(pushTy==0){
            body=@"您有一条图片信息";
        }
    }
    else if(msg.messageType==MSG_TYPE_TEXT){
        //邓肯
        NSInteger pushTy=[FlappyStringTool toUnNullZeroStr:[[FlappyData shareInstance]getPushType]].integerValue;
        //普通
        if(pushTy==0){
            body=@"您有一条语音信息";
        }
    }
    //badge
    NSInteger badge = 1;
    //时间
    NSInteger timeInteval = 5;
    //用户信息
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]init];
    userInfo[@"message"]=[FlappyJsonTool JSONObjectToJSONString:[msg mj_keyValues]];
    if (@available(iOS 10.0, *)) {
        // 1.创建通知内容
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.sound = [UNNotificationSound defaultSound];
        content.title = title;
        content.body = body;
        content.badge = @(badge);
        content.userInfo = userInfo;
        
        //// 2.设置通知附件内容
        //NSError *error = nil;
        //NSString *path = [[NSBundle mainBundle] pathForResource:@"logo_img_02@2x" ofType:@"png"];
        //UNNotificationAttachment *att = [UNNotificationAttachment attachmentWithIdentifier:@"att1" URL:[NSURL fileURLWithPath:path] options:nil error:&error];
        //if (error) {
        //    NSLog(@"attachment error %@", error);
        //}
        //content.attachments = @[att];
        //content.launchImageName = @"icon_certification_status1@2x";
        
        // 2.设置声音
        UNNotificationSound *sound = [UNNotificationSound defaultSound];
        // [UNNotificationSound defaultSound];
        content.sound = sound;
        // 3.触发模式
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInteval repeats:NO];
        
        // 4.设置UNNotificationRequest
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:msg.messageId
                                                                              content:content
                                                                              trigger:trigger];
        
        // 5.把通知加到UNUserNotificationCenter, 到指定触发点会被触发
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        }];
    } else {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        // 1.设置触发时间（如果要立即触发，无需设置）
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
        // 2.设置通知标题
        localNotification.alertBody = title;
        // 3.设置通知动作按钮的标题
        localNotification.alertAction = @"查看";
        // 4.设置提醒的声音
        localNotification.soundName = @"sound01.wav";
        // 5.设置通知的 传递的userInfo
        localNotification.userInfo = userInfo;
        // 6.在规定的日期触发通知
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        // 6.立即触发一个通知
        //[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
}

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
        NSString *token = [NSString
                           stringWithFormat:@"%@",deviceToken];
        token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
        token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
        token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
        deviceTokenStr=[NSMutableString stringWithFormat:@"%@",token];
    }
    
    //设置token
    [self setUUID:deviceTokenStr];
    
    //更新字符串
    [self updateDeviceToken:deviceTokenStr];
}

//更新deviceToken
-(void)updateDeviceToken:(NSString*)deviceTokenStr{
    //如果当前是登录的状态
    if([[FlappyData shareInstance]getUser]!=nil&&[[FlappyData shareInstance]getUser].login==true){
        
        //没有设置或者不相同
        if([[FlappyData shareInstance]getUser].pushID==nil||![[[FlappyData shareInstance]getUser].pushID isEqualToString:deviceTokenStr]){
            //请求体，参数（NSDictionary 类型）
            NSDictionary *parameters = @{@"userExtendID":[[FlappyData shareInstance]getUser].userExtendId,
                                         @"device":DEVICE_TYPE,
                                         @"pushid":deviceTokenStr
            };
            //注册地址
            NSString *urlString = [FlappyApiConfig shareInstance].URL_changePush;
            //循环引用
            __weak typeof(self) safeSelf=self;
            //请求数据
            [FlappyApiRequest postRequest:urlString
                           withParameters:parameters
                              withSuccess:^(id data) {
                //保存
                ChatUser* user=[[FlappyData shareInstance]getUser];
                user.pushID=deviceTokenStr;
                [[FlappyData shareInstance]saveUser:user];
                
            } withFailure:^(NSError * error, NSInteger code) {
                [NSObject cancelPreviousPerformRequestsWithTarget:safeSelf
                                                         selector:@selector(updateDeviceToken:)
                                                           object:deviceTokenStr];
                //修改失败
                [safeSelf performSelector:@selector(updateDeviceToken:)
                               withObject:deviceTokenStr
                               afterDelay:[FlappyApiConfig shareInstance].autoLoginInterval];
            }];
        }
    }
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

//设置推送平台
-(void)setPushPlatfrom:(NSString*)platform{
    [FlappyApiConfig shareInstance].pushPlat=platform;
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
-(void)addSessionListener:(SessionListener)listener{
    [self.sessionListeners addObject:listener];
}

//移除会话监听
-(void)removeSessionListener:(SessionListener)listener{
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
-(void)createAccount:(NSString*)userID
         andUserName:(NSString*)userName
       andUserAvatar:(NSString*)userAvatar
         andUserData:(NSString*)userData
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure{
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_register;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendID":userID,
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
-(void)updateAccount:(NSString*)userID
         andUserName:(NSString*)userName
       andUserAvatar:(NSString*)userAvatar
         andUserData:(NSString*)userData
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure{
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_update;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendID":userID,
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
-(void)login:(NSString*)userExtendID
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
        NSDictionary *parameters = @{@"userID":@"",
                                     @"userExtendID":userExtendID,
                                     @"device":DEVICE_TYPE,
                                     @"pushid":self.pushID,
                                     @"pushplat":[FlappyApiConfig shareInstance].pushPlat
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
        
        //保存推送状态数据
        [self savePushData:data];
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
        NSDictionary *parameters = @{@"userID":[[FlappyData shareInstance] getUser].userId,
                                     @"device":DEVICE_TYPE,
                                     @"pushid":self.pushID,
                                     @"pushplat":[FlappyApiConfig shareInstance].pushPlat
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
        
        //保存推送类型数据
        [self savePushData:data];
        
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
        NSDictionary *parameters = @{@"userID":@"",
                                     @"userExtendID":[[FlappyData shareInstance]getUser].userExtendId,
                                     @"device":DEVICE_TYPE,
                                     @"pushid":self.pushID,
                                     @"pushplat":[FlappyApiConfig shareInstance].pushPlat
        };
        //请求数据
        [FlappyApiRequest postRequest:urlString
                       withParameters:parameters
                          withSuccess:^(id data) {
            //退出登录成功
            success(data);
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
        id dataType=data[@"route"][@"routePushType"];
        //推送类型
        NSInteger type=(long)dataType;
        //设置
        [[FlappyData shareInstance]savePushType:[NSString stringWithFormat:@"%ld",(long)type]];
    } @catch (NSException *exception) {
        //打印错误日志
        NSLog(@"FlappyIM:%@",exception.description);
    }
}

//创建两个人的会话
-(void)createSingleSession:(NSString*)userTwo
                andSuccess:(FlappySuccess)success
                andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_createSingleSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userOne":[[FlappyData shareInstance]getUser].userExtendId,
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

//网络获取单聊用户的会话，没有就会创建
-(void)getSingleSessionHttp:(NSString*)userTwo
                 andSuccess:(FlappySuccess)success
                 andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    
    //注册地址
    NSString *urlString = [FlappyApiConfig shareInstance].URL_createSingleSession;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userOne":[[FlappyData shareInstance]getUser].userExtendId,
                                 @"userTwo":userTwo,
    };
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        SessionData* model=[SessionData mj_objectWithKeyValues:data];
        //创建session
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=model;
        success(session);
    } withFailure:^(NSError * error, NSInteger code) {
        //登录失败，清空回调
        failure(error,code);
    }];
}

//获取单聊的会话
-(void)getSingleSession:(NSString*)userTwo
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //创建
    NSMutableArray* array=[[NSMutableArray alloc]init];
    [array addObject:userTwo];
    [array addObject:[FlappyData shareInstance].getUser.userExtendId];
    NSArray *newArray = [array sortedArrayUsingComparator:^(NSString * obj1, NSString * obj2){
        return (NSComparisonResult)[obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接
    NSString* extendID=[NSString stringWithFormat:@"%@-%@",newArray[0],newArray[1]];
    //获取当前用户下，当前的会话
    SessionData* data=[[FlappyDataBase shareInstance] getUserSessionByExtendID:extendID];
    if(data!=nil){
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=data;
        success(session);
    }else{
        [self getSingleSessionHttp:userTwo
                        andSuccess:success
                        andFailure:failure];
    }
}


//创建群组会话
-(void)createGroupSession:(NSArray*)users
              withGroupID:(NSString*)groupID
            withGroupName:(NSString*)groupName
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //转换为data
    NSData *usersData=[NSJSONSerialization dataWithJSONObject:users
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:nil];
    //转换为字符串
    NSString *jsonStr=[[NSString alloc]initWithData:usersData
                                           encoding:NSUTF8StringEncoding];
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_createGroupSession;
    
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"users":jsonStr,
                                 @"createUser":[[FlappyData shareInstance]getUser].userId,
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
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=model;
        success(session);
    } withFailure:^(NSError * error, NSInteger code) {
        //登录失败，清空回调
        failure(error,code);
    }];
    
}

//通过获取会话
-(void)getSessionByExtendIDHttp:(NSString*)extendID
                     andSuccess:(FlappySuccess)success
                     andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getSessionByExtendID;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"extendID":extendID};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        //获取model
        SessionData* model=[SessionData mj_objectWithKeyValues:data];
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
-(void)getSessionByExtendID:(NSString*)extendID
                 andSuccess:(FlappySuccess)success
                 andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //获取当前用户下，当前的会话
    SessionData* data=[[FlappyDataBase shareInstance] getUserSessionByExtendID:extendID];
    //成功
    if(data!=nil){
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=data;
        success(session);
    }else{
        //获取用户会话
        [self getSessionByExtendIDHttp:extendID
                            andSuccess:success
                            andFailure:failure];
    }
}

//获取用户的sessions
-(void)getUserSessions:(FlappySuccess)success
            andFailure:(FlappyFailure)failure{
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //创建返回
    NSMutableArray* ret=[[NSMutableArray alloc]init];
    //获取当前用户的所有
    NSMutableArray* array=[[FlappyDataBase shareInstance] getUserSessions:[FlappyData shareInstance].getUser.userExtendId];
    for(int s=0;s<array.count;s++){
        //获取model
        SessionData* model=[SessionData mj_objectWithKeyValues:[array objectAtIndex:s]];
        FlappyChatSession* session=[[FlappyChatSession alloc] init];
        session.session=model;
        [ret addObject:session];
    }
    
    //进行一个排序
    NSArray* sortArray = [ret sortedArrayUsingComparator:^NSComparisonResult(FlappyChatSession* _Nonnull one,
                                                                             FlappyChatSession* _Nonnull two) {
        if(one.session.sessionType==TYPE_SYSTEM ){
            return NSOrderedAscending;
        }
        if(two.session.sessionType==TYPE_SYSTEM){
            return NSOrderedDescending;
        }
        ChatMessage* msgOne=[one getLatestMessage];
        ChatMessage* msgTwo=[two getLatestMessage];
        if(msgOne==nil){
            return NSOrderedDescending;
        }
        if(msgTwo==nil){
            return NSOrderedAscending;
        }
        if(msgOne.messageTableSeq>msgTwo.messageTableSeq){
            return NSOrderedAscending;
        }else{
            return NSOrderedDescending;
        }
    }];
    ret = [[NSMutableArray alloc] initWithArray:sortArray];
    
    //成功
    if(ret!=nil && ret.count!= 0){
        success(ret);
    }else{
        //没有拿到就联网去拿
        [self getUserSessionsHttp:success
                       andFailure:failure];
    }
}


//获取用户的sessions
-(void)getUserSessionsHttp:(FlappySuccess)success
                andFailure:(FlappyFailure)failure{
    
    //为空直接出错
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
        return ;
    }
    //创建群组会话
    NSString *urlString = [FlappyApiConfig shareInstance].URL_getUserSessions;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendID":[[FlappyData shareInstance]getUser].userExtendId};
    //请求数据
    [FlappyApiRequest postRequest:urlString
                   withParameters:parameters
                      withSuccess:^(id data) {
        
        NSMutableArray* array=data;
        NSMutableArray* ret=[[NSMutableArray alloc]init];
        
        for(int s=0;s<array.count;s++){
            //获取model
            SessionData* model=[SessionData mj_objectWithKeyValues:[array objectAtIndex:s]];
            FlappyChatSession* session=[[FlappyChatSession alloc] init];
            session.session=model;
            [ret addObject:session];
        }
        
        //进行一个排序
        NSArray* sortArray = [ret sortedArrayUsingComparator:^NSComparisonResult(FlappyChatSession* _Nonnull one,
                                                                                 FlappyChatSession* _Nonnull two) {
            if(one.session.sessionType==TYPE_SYSTEM ){
                return NSOrderedAscending;
            }
            if(two.session.sessionType==TYPE_SYSTEM){
                return NSOrderedDescending;
            }
            ChatMessage* msgOne=[one getLatestMessage];
            ChatMessage* msgTwo=[two getLatestMessage];
            if(msgOne==nil){
                return NSOrderedDescending;
            }
            if(msgTwo==nil){
                return NSOrderedAscending;
            }
            if(msgOne.messageTableSeq>msgTwo.messageTableSeq){
                return NSOrderedAscending;
            }else{
                return NSOrderedDescending;
            }
        }];
        ret = [[NSMutableArray alloc] initWithArray:sortArray];
        
        //成功
        success(ret);
        
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
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
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
    if([[FlappyData shareInstance]getUser]==nil){
        //返回没有登录
        failure([NSError errorWithDomain:@"Not login" code:0 userInfo:nil],RESULT_NOTLOGIN);
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
