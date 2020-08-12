//
//  FlappyIM.h
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "ChatMessage.h"
#import "ChatUser.h"
#import "ChatVideo.h"
#import "ChatVoice.h"
#import "ChatImage.h"
#import "Flappy.pbobjc.h"
#import "FlappyChatSession.h"
#import "FlappyApiRequest.h"
#import "FlappySocket.h"
#import "ReachabilityFlappy.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking-umbrella.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>


NS_ASSUME_NONNULL_BEGIN


@interface FlappyIM : NSObject<GCDAsyncSocketDelegate,UNUserNotificationCenterDelegate>


//推送的ID
@property (nonatomic,copy) NSString*  pushID;

//当前是否活跃
@property (nonatomic,assign) bool  isActive;

//回调
@property (nonatomic,strong) NSMutableDictionary*  msgListeners;

//会话间隔
@property (nonatomic,strong) NSMutableArray*  sessinListeners;

//单例模式
+ (instancetype)shareInstance;

//重设用户名和密码
-(void)resetServer:(NSString*)serverUrl
      andUploadUrl:(NSString*)upload;

//注册远程的通知
-(void)registerRemoteNotice:(UIApplication *)application;

//点击通知
-(void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

//注册设备信息
-(void)registerDeviceToken:(NSData *)deviceToken;

//初始化
-(void)setup;

//通过服务器地址初始化
-(void)setup:(NSString*)serverUrl  withUploadUrl:(NSString*)uploadUrl;

//设置当前的平台
-(void)setPlatfrom:(NSString*)platform;

//判断当前账号是否登录
-(Boolean)isLogin;

//获取登录信息
-(ChatUser*)getLoginInfo;


//创建账号
-(void)createAccount:(NSString*)userID
         andUserName:(NSString*)userName
         andUserHead:(NSString*)userHead
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure;

//登录账号
-(void)login:(NSString*)userExtendID
  andSuccess:(FlappySuccess)success
  andFailure:(FlappyFailure)failure;


//退出登录
-(void)logout:(FlappySuccess)success
   andFailure:(FlappyFailure)failure;


//创建单聊会话
-(void)createSingleSession:(NSString*)userTwo
                andSuccess:(FlappySuccess)success
                andFailure:(FlappyFailure)failure;


//获取单聊会话
-(void)getSingleSession:(NSString*)userTwo
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure;


//创建群组会话
-(void)createGroupSession:(NSArray*)users
              withGroupID:(NSString*)groupID
            withGroupName:(NSString*)groupName
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure;

//获取群组会话
-(void)getSessionByExtendID:(NSString*)extendID
           andSuccess:(FlappySuccess)success
           andFailure:(FlappyFailure)failure;


//获取用户的所有会话列表
-(void)getUserSessions:(FlappySuccess)success
            andFailure:(FlappyFailure)failure;


//添加用户到群组
-(void)addUserToSession:(NSString*)userID
            withGroupID:(NSString*)groupID
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure;


//删除群组中的某个用户
-(void)delUserInSession:(NSString*)userID
            withGroupID:(NSString*)groupID
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure;



//增加所有消息的监听
-(void)addGloableMsgListener:(MessageListener)listener;

//移除所有消息的监听
-(void)removeGloableMsgListener:(MessageListener)listener;


//增加某个session的监听
-(void)addMsgListener:(MessageListener)listener
     withSessionID:(NSString*)sessionID;


//移除某个session的监听
-(void)removeMsgListener:(MessageListener)listener
        withSessionID:(NSString*)sessionID;


//设置被踢下线的监听
-(void)setKnickedListener:(__nullable FlappyKnicked)knicked;


//设置notification被点击的通知
-(void)setNotifyClickListener:(__nullable NotifyClickListener)clicked;


//新增会话监听
-(void)addSessinListener:(SessionListener)listener;


//移除会话监听
-(void)removeSessinListener:(SessionListener)listener;



@end

NS_ASSUME_NONNULL_END
