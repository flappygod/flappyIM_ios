//
//  FlappyIM.h
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "ApiConfig.h"
#import "User.h"
#import "MJExtension.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "Flappy.pbobjc.h"
#import "FlappyData.h"
#import "ChatMessage.h"
#import "NetTool.h"
#import "DataBase.h"
#import "FlappySession.h"
#import "PostTool.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Reachability/Reachability.h>
#import <AFNetworking/AFNetworking.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

//登录之后非正常关闭
typedef void(^FlappyDead) (void);

//请求失败
typedef void(^FlappyFailure) (NSError *_Nullable,NSInteger);

//请求成功
typedef void(^FlappySuccess) (id _Nullable);

//消息监听
typedef void(^MessageListener) (ChatMessage* _Nullable message);

NS_ASSUME_NONNULL_BEGIN


@interface FlappyIM : NSObject<GCDAsyncSocketDelegate>

//单例模式
+ (instancetype)shareInstance;

//初始化
-(void)setup;


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


//增加消息的监听
-(void)addListener:(MessageListener)listener;


//增加某个session的监听
-(void)addListener:(MessageListener)listener
     withSessionID:(NSString*)sessionID;


//移除监听
-(void)removeListener:(MessageListener)listener;


@end

NS_ASSUME_NONNULL_END
