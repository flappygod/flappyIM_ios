//
//  FlappyIM.h
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "PostTool.h"


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


@end

NS_ASSUME_NONNULL_END
