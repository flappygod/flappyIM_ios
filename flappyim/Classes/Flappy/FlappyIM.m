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


@interface FlappyIM ()

//用于监听网络变化
@property (nonatomic,strong) Reachability* hostReachability;
//用于监听网络变化
@property (nonatomic,strong) Reachability* internetReachability;
//用于联网的socket
@property (nonatomic,strong) FlappySocket* flappysocket;
//被踢下线了
@property (nonatomic,strong) FlappyKnicked knicked;
//消息通知被点击了
@property (nonatomic,strong) NotifyClickListener notifyClicked;




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
        _sharedSingleton.callbacks=[[NSMutableDictionary alloc] init];
        //初始化本地推送
        [_sharedSingleton initLocalNotification];
    });
    return _sharedSingleton;
}

//增加本地通知
-(void)initLocalNotification{
    //后台了，但是还没有被墓碑的情况
    __weak typeof(self) safeSelf=self;
    //监听是否发送本地通知
    [self addGloableListener:^(ChatMessage * _Nullable message) {
        //判断当前是在后台还是前台，如果是在后台，那么
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        //如果再后台
        if(state == UIApplicationStateBackground){
            //判断当前是在后台还是在前台
            [safeSelf sendLocalNotification:message];
        }
    }];
}


//发送本地通知
- (void)sendLocalNotification:(ChatMessage*)msg{
    //标题
    NSString *title = @"消息提醒";
    //新的信息
    NSString *body =  @"您有一条新的信息";
    //消息类型
    if(msg.messageType==MSG_TYPE_TEXT){
        //邓肯
        NSInteger pushTy=[FlappyStringTool toUnNullZeroStr:[FlappyData getPushType]].integerValue;
        //普通
        if(pushTy==0){
            body=[msg getChatText];
        }
    }
    else if(msg.messageType==MSG_TYPE_IMG){
        //邓肯
        NSInteger pushTy=[FlappyStringTool toUnNullZeroStr:[FlappyData getPushType]].integerValue;
        //普通
        if(pushTy==0){
            body=@"您有一条图片信息";
        }
    }
    else if(msg.messageType==MSG_TYPE_TEXT){
        //邓肯
        NSInteger pushTy=[FlappyStringTool toUnNullZeroStr:[FlappyData getPushType]].integerValue;
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
        [content setValue:@(YES) forKeyPath:@"shouldAlwaysAlertWhileAppIsForeground"];
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
        UNNotificationSound *sound = [UNNotificationSound soundNamed:@"sound01.wav"];
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

//获取唯一的ID
+(NSString*)getUUID{
    NSString* former=[FlappyData getPush];
    if([FlappyStringTool isStringEmpty:former]){
        NSString* UUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [FlappyData savePush:UUID];
    }
    return [FlappyData getPush];
}

//设备的token
-(void)setUUID:(NSString*)token{
    //设置
    [FlappyData savePush:token];
    //获取唯一的推送ID
    self.pushID=token;
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

//监听到本地的通知
-(void)didReceiveRemoteNotification:(NSDictionary *)userInfo{
    if(self.notifyClicked!=nil){
        //获取消息
        NSString* msg=userInfo[@"message"];
        //转换为消息体
        self.notifyClicked([ChatMessage mj_objectWithKeyValues:[FlappyJsonTool JSONStringToDictionary:msg]]);
    }
}

//注册
-(void)registerDeviceToken:(NSData *)deviceToken{
    NSMutableString *deviceTokenStr = [NSMutableString string];
    const char *bytes = deviceToken.bytes;
    long iCount = deviceToken.length;
    for (long i = 0; i < iCount; i++) {
        [deviceTokenStr appendFormat:@"%02x", bytes[i]&0x000000FF];
    }
    //设置token
    [self setUUID:deviceTokenStr];
    
    //如果当前是登录的状态
    if([FlappyData getUser]!=nil&&[FlappyData getUser].login==true){
        
        //没有设置或者不相同
        if([FlappyData getUser].pushID==nil||![[FlappyData getUser].pushID isEqualToString:deviceTokenStr]){
            //请求体，参数（NSDictionary 类型）
            NSDictionary *parameters = @{@"userID":@"",
                                         @"userExtendID":[FlappyData getUser].userExtendId,
                                         @"device":DEVICE_TYPE,
                                         @"pushid":deviceTokenStr
                                         };
            //创建
            self.flappysocket=[[FlappySocket alloc] init];
            
            //注册地址
            NSString *urlString = [FlappyApiConfig shareInstance].URL_login;
            //请求数据
            [FlappyApiRequest postRequest:urlString
                           withParameters:parameters
                              withSuccess:^(id data) {
                                  //保存
                                  ChatUser* user=[FlappyData getUser];
                                  user.pushID=deviceTokenStr;
                                  [FlappyData saveUser:user];
                                  
                              } withFailure:^(NSError * error, NSInteger code) {
                                  //修改失败
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
    ChatUser* user=[FlappyData getUser];
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
    [[FlappyDataBase shareInstance] setup];
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
    if([FlappyNetTool getCurrentNetworkState]!=0){
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
                          
                          @try {
                              //推送类型
                              NSInteger type=data[@"route"][@"routePushType"];
                              [FlappyData savePushType:[NSString stringWithFormat:@"%ld",(long)type]];
                          } @catch (NSException *exception) {
                          } @finally {
                          }
                          
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
                          
                          //保存推送类型
                          @try {
                              //推送类型
                              NSInteger type=data[@"route"][@"routePushType"];
                              [FlappyData savePushType:[NSString stringWithFormat:@"%ld",(long)type]];
                          } @catch (NSException *exception) {
                          } @finally {
                          }
                          
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

//获取单聊的会话
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
-(void)createGroupSession:(NSArray*)users
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


//通过extendID获取
-(void)getSessionByID:(NSString*)extendID
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
    NSDictionary *parameters = @{@"extendID":extendID};
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


//IOS 10以上预处理
#pragma mark - UNUserNotificationCenterDelegate
//在展示通知前进行处理，即有机会在展示通知前再修改通知内容。
-(void)userNotificationCenter:(UNUserNotificationCenter *)center
      willPresentNotification:(UNNotification *)notification
        withCompletionHandler:(void(^)(UNNotificationPresentationOptions))completionHandler{
    //1. 处理通知
    //2. 处理完成后条用 completionHandler ，用于指示在前台显示通知的形式
    completionHandler(UNNotificationPresentationOptionAlert+UNNotificationPresentationOptionSound+UNNotificationPresentationOptionBadge);
}


// 通知的点击事件
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler{
    //用户推送的信息
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    // 收到推送的请求
    UNNotificationRequest *request = response.notification.request;
    // 收到推送的消息内容
    UNNotificationContent *content = request.content;
    // 推送消息的角标
    NSNumber *badge = content.badge;
    // 推送消息体
    NSString *body = content.body;
    // 推送消息的声音
    UNNotificationSound *sound = content.sound;
    // 推送消息的副标题
    NSString *subtitle = content.subtitle;
    // 推送消息的标题
    NSString *title = content.title;
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