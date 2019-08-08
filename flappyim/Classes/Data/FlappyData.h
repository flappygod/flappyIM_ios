//
//  FlappyData.h
//  flappyim
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "Flappy.pbobjc.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyData : NSObject


//保存用户信息
+(void)saveUser:(User*)user;

//获取当前登录的用户
+(User*)getUser;

//清空用户
+(void)clearUser;



@end

NS_ASSUME_NONNULL_END
