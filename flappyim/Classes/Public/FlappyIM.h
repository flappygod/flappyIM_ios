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
#import "FlappyReachability.h"
#import "PushSettings.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking-umbrella.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "FlappyMessageListener.h"
#import "FlappySessionListener.h"



NS_ASSUME_NONNULL_BEGIN


@interface FlappyIM : NSObject<GCDAsyncSocketDelegate,UNUserNotificationCenterDelegate>


//当前是否活跃
@property (nonatomic,assign) bool  isForground;

//消息创建、发送
@property (nonatomic,strong) NSMutableDictionary*  messageListeners;

//会话间隔
@property (nonatomic,strong) NSMutableArray*  sessionListeners;

//单例模式
+ (instancetype)shareInstance;

//通过服务器地址初始化
-(void)init:(NSString*)serverUrl  assetsUrl:(NSString*)uploadUrl;

//鉴权
-(void)auth:(NSString*)token;

//开启服务
-(void)startService;

//关闭服务
-(void)stopService;


//重设用户名和密码
-(void)resetServer:(NSString*)serverUrl
      andUploadUrl:(NSString*)upload;

//注册远程的通知
-(void)registerRemoteNotice:(UIApplication *)application;

//点击通知
-(void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

//注册设备信息
-(void)registerDeviceToken:(NSData *)deviceToken;

//设置推送类型
-(void)setPushType:(NSString*)pushType;

//设置当前的平台
-(void)setPushPlat:(NSString*)pushPlat;

//设置RsaPublicKey
-(void)setRsaPublicKey:(NSString*)key;

//获取RsaPublicKey
-(NSString*)getRsaPublicKey;

//设置当前的推送信息
-(void)changePushType:(nullable NSString*)pushType
          andPushPlat:(nullable NSString*)pushPlat
            andPushId:(nullable NSString*)pushId
          andLanguage:(nullable NSString*)pushLanguage
           andPrivacy:(nullable NSString*)pushPrivacy
              andMute:(nullable NSString*)pushMute
           andSuccess:(nullable FlappySuccess)success
           andFailure:(nullable FlappyFailure)failure;


//设置当前的推送信息
-(PushSettings*)getPushSettings;


//判断当前账号是否登录
-(Boolean)isLogin;

//判断当前是否在线
-(Boolean)isOnline;

//获取登录信息
-(ChatUser*)getLoginInfo;


//创建账号
-(void)createAccount:(NSString*)userID
         andUserName:(NSString*)userName
       andUserAvatar:(NSString*)userAvatar
         andUserData:(NSString*)userData
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure;

//更新账号信息
-(void)updateAccount:(NSString*)userID
         andUserName:(NSString*)userName
       andUserAvatar:(NSString*)userAvatar
         andUserData:(NSString*)userData
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
-(void)createSingleSessionByPeer:(NSString*)peerExtendId
                      andSuccess:(FlappySuccess)success
                      andFailure:(FlappyFailure)failure;


//获取单聊会话
-(void)getSingleSessionByPeer:(NSString*)peerExtendId
                   andSuccess:(FlappySuccess)success
                   andFailure:(FlappyFailure)failure;


//创建群组会话
-(void)createGroupSession:(NSArray*)users
              withSessionExtendId:(NSString*)groupID
            withSessionName:(NSString*)groupName
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure;


//通过sessionID获取
-(void)getSessionById:(NSString*)sessionId
           andSuccess:(FlappySuccess)success
           andFailure:(FlappyFailure)failure;


//获取群组会话
-(void)getSessionByExtendId:(NSString*)sessionExtendId
                 andSuccess:(FlappySuccess)success
                 andFailure:(FlappyFailure)failure;


//获取用户的所有会话列表
-(void)getUserSessionList:(FlappySuccess)success
               andFailure:(FlappyFailure)failure;


//添加用户到群组
-(void)addUserToSession:(NSString*)userId
            withGroupID:(NSString*)groupId
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure;


//删除群组中的某个用户
-(void)delUserInSession:(NSString*)userId
            withGroupID:(NSString*)groupId
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure;


//搜索文本消息
-(NSMutableArray *)searchTextMessage:(NSString*)text
                        andSessionId:(NSString*)sessionId
                        andMessageId:(NSString*)messageId
                             andSize:(NSInteger)size;

//搜索图片消息
-(NSMutableArray *)searchImageMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size;

//搜索消息之前的视频消息
-(NSMutableArray *)searchVideoMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size;

//搜索消息之前的语音消息
-(NSMutableArray *)searchVoiceMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size;

//增加所有消息的监听
-(void)addGloableMsgListener:(FlappyMessageListener*)listener;

//移除所有消息的监听
-(void)removeGloableMsgListener:(FlappyMessageListener*)listener;


//增加某个session的监听
-(void)addMsgListener:(FlappyMessageListener*)listener
        withSessionID:(NSString*)sessionID;


//移除某个session的监听
-(void)removeMsgListener:(FlappyMessageListener*)listener
           withSessionID:(NSString*)sessionID;


//设置被踢下线的监听
-(void)setKickedListener:(__nullable FlappyKickedListener)knicked;


//设置踢下线
-(void)setKickedOut;


//设置notification被点击的通知
-(void)setNotificationClickListener:(__nullable NotificationClickListener)clicked;


//新增会话监听
-(void)addSessionListener:(FlappySessionListener*)listener;


//移除会话监听
-(void)removeSessionListener:(FlappySessionListener*)listener;


@end

NS_ASSUME_NONNULL_END
