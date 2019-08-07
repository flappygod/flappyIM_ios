//
//  FlappyIM.h
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>



//请求失败
typedef void(^FlappyFailure) (NSError *_Nullable,NSInteger);

//请求成功
typedef void(^FlappySuccess) (id _Nullable);


NS_ASSUME_NONNULL_BEGIN


@interface FlappyIM : NSObject<GCDAsyncSocketDelegate>

//单例模式
+ (instancetype)shareInstance;


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



@end

NS_ASSUME_NONNULL_END
