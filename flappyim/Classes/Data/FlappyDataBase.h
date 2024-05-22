//
//  DataBase.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "ChatMessage.h"
#import "SessionData.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyDataBase : NSObject

//单例模式
+ (instancetype)shareInstance;

//初始化数据库
-(void)setup;

//清空发送的消息
-(void)clearSendingMessage;

//插入单条会话
-(Boolean)insertSession:(SessionData*)data;

//插入多条会话
-(Boolean)insertSessions:(NSMutableArray*)array;

//插入会话的用户
-(Boolean)insertSessionMember:(SessionDataMember*) member;

//获取当前用户的所有会话
-(NSMutableArray*)getUserSessions:(NSString*)userExtendID;

//获取用户的指定会话
-(SessionData*)getUserSessionByExtendID:(NSString*)sessionExtendId;

//获取用户的指定会话
-(SessionData*)getUserSessionByID:(NSString*)sessionId;

//删除用户的会话
-(Boolean)deleteUserSession:(NSString*)sessionId;

//插入单条消息
-(void)insertMessage:(ChatMessage*)msg;

//插入消息列表
-(void)insertMessages:(NSMutableArray*)array;

//处理消息Action更新操作
-(void)handleActionMessageUpdate:(ChatMessage*)msg;

//通过ID获取消息
-(ChatMessage*)getMessageById:(NSString*)messageID;

//更新数据
-(Boolean)updateMessage:(ChatMessage*)msg;

//通过会话ID获取最近的一次会话
-(ChatMessage*)getSessionLatestMessage:(NSString*)sessionID;

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessageBySessionId:(NSString*)sessionID;

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessage;

//通过sessionID，获取之前的
-(NSMutableArray*)getSessionFormerMessage:(NSString*)sessionID
                            withMessageID:(NSString*)messageId
                                 withSize:(NSInteger)size;

//获取未读消息的数量
-(int)getSessionUnReadMessageCount:(NSString*)sessionId;

@end

NS_ASSUME_NONNULL_END
