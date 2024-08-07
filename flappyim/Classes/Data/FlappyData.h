//
//  FlappyData.h
//  flappyim
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "Flappy.pbobjc.h"
#import "ChatUser.h"
#import "PushSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyData : NSObject


//使用单例模式
+ (instancetype)shareInstance;


//保存用户信息
-(void)saveUser:(ChatUser*)user;

//获取当前登录的用户
-(ChatUser*)getUser;

//清空用户
-(void)clearUser;

//保存
-(void)savePushId:(NSString*)pushID;

//获取推送ID
-(NSString*)getPushId;

//获取设备ID
-(NSString*)getDeviceId;

//保存推送设置
-(void)savePushSetting:(PushSettings*)setting;

//获取推送设置
-(PushSettings*)getPushSetting;

//RSA秘钥
-(void)saveRsaKey:(NSString*)key;

//获取RSA秘钥
-(NSString*)getRsaKey;


@end

NS_ASSUME_NONNULL_END
