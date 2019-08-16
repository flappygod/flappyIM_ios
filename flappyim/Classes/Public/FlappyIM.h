//
//  FlappyIM.h
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "ChatMessage.h"
#import "ChatUser.h"
#import "Flappy.pbobjc.h"
#import "ChatSingleSession.h"
#import "ChatGroupSession.h"
#import "PostTool.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Reachability/Reachability.h>
#import <AFNetworking/AFNetworking.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>




NS_ASSUME_NONNULL_BEGIN


@interface FlappyIM : NSObject<GCDAsyncSocketDelegate>

//单例模式
+ (instancetype)shareInstance;

//初始化
-(void)setup;


//判断当前账号是否登录
-(Boolean)isLogin;


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
-(void)logout:(NSString*)userExtendID
   andSuccess:(FlappySuccess)success
   andFailure:(FlappyFailure)failure;


//创建session
-(void)createSession:(NSString*)userTwo
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure;


//创建群组会话
-(void)createGroupSession:(NSString*)users
              withGroupID:(NSString*)groupID
            withGroupName:(NSString*)groupName
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure;

//获取群组会话
-(void)getGroupSession:(NSString*)groupID
            andSuccess:(FlappySuccess)success
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
-(void)addGloableListener:(MessageListener)listener;

//移除所有消息的监听
-(void)removeGloableListener:(MessageListener)listener;


//增加某个session的监听
-(void)addListener:(MessageListener)listener
     withSessionID:(NSString*)sessionID;

//移除某个session的监听
-(void)removeListener:(MessageListener)listener
        withSessionID:(NSString*)sessionID;


//设置被踢下线的监听
-(void)setKnickedListener:(__nullable FlappyKnicked)knicked;




@end

NS_ASSUME_NONNULL_END
