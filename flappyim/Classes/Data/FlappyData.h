//
//  FlappyData.h
//  flappyim
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "Flappy.pbobjc.h"
#import "ChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyData : NSObject


//保存用户信息
+(void)saveUser:(ChatUser*)user;

//获取当前登录的用户
+(ChatUser*)getUser;

//清空用户
+(void)clearUser;

//保存
+(void)savePush:(NSString*)pushID;

//获取推送ID
+(NSString*)getPush;


+(void)savePushType:(NSString*)type;

+(void)getPushType:(NSString*)type;


@end

NS_ASSUME_NONNULL_END
