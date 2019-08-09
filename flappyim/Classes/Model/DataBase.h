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

//通过ID获取消息
-(ChatMessage*)getMessageByID:(NSString*)messageID;

//更新数据
-(Boolean)updateMessage:(ChatMessage*)msg;

//通过会话ID获取最近的一次会话
-(ChatMessage*)getLatestMessageBySession:(NSString*)sessionID;


//通过sessionID，获取之前的
-(NSMutableArray*)getSessionMessage:(NSString*)sessionID
                         withOffset:(NSInteger)offset
                           withSize:(NSInteger)size;

@end

NS_ASSUME_NONNULL_END
