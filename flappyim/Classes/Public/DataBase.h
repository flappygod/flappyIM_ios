//
//  DataBase.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "ChatMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface DataBase : NSObject

//单例模式
+ (instancetype)shareInstance;

//初始化数据库
-(void)setup;

//插入消息
-(Boolean)insert:(ChatMessage*)msg;

@end

NS_ASSUME_NONNULL_END
