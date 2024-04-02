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
-(void)savePush:(NSString*)pushID;

//获取推送ID
-(NSString*)getPush;

//保存推送设置
-(void)savePushSetting:(PushSettings*)setting;

//获取推送设置
-(PushSettings*)getPushSetting;

//保存推送展示类型
-(void)savePushType:(NSString*)type;

//获取推送展示类型
-(NSString*)getPushType;


@end

NS_ASSUME_NONNULL_END
