//
//  DataBase.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "ChatMessage.h"
#import "ChatSessionData.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyDataBase : NSObject

//单例模式
+ (instancetype)shareInstance;

//初始化数据库
-(void)setup;

//清空发送的消息
-(void)clearSendingMessage;

//插入单条会话
-(Boolean)insertSession:(ChatSessionData*)data;

//插入多条会话
-(Boolean)insertSessions:(NSMutableArray*)array;

//插入会话的用户
-(Boolean)insertSessionMember:(ChatSessionMember*) member;

//获取当前用户的所有会话
-(NSMutableArray*)getUserSessions:(NSString*)userExtendID;

//获取用户的指定会话
-(ChatSessionData*)getUserSessionByExtendId:(NSString*)sessionExtendId;

//获取用户的指定会话
-(ChatSessionData*)getUserSessionByID:(NSString*)sessionId;

//删除用户的会话
-(Boolean)deleteUserSession:(NSString*)sessionId;

//设置会话是否可用
-(Boolean)setUserSession:(NSString *)sessionId
                isEnable:(NSInteger)enable;

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

//获取当前最近的一条发送成功的消息的offset
-(NSInteger)getSessionOffsetLatest:(NSString *)sessionID;

//通过会话ID获取最近的一次会话
-(ChatMessage*)getSessionLatestMessage:(NSString*)sessionID;

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessageBySessionId:(NSString*)sessionID;

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessage;

//通过sessionID，获取之前的
-(NSMutableArray*)getSessionFormerMessages:(NSString*)sessionID
                            withMessageID:(NSString*)messageId
                                 withSize:(NSInteger)size;
//通过sessionID，获取之后的
-(NSMutableArray *)getSessionNewerMessages:(NSString *)sessionID
                             withMessageID:(NSString *)messageId
                                  withSize:(NSInteger)size;


//搜索文本消息
-(NSMutableArray *)searchTextMessage:(NSString*)text
                        andSessionId:(NSString*)sessionId
                        andMessageId:(NSString*)messageId
                             andSize:(NSInteger)size;

//搜索图片消息
-(NSMutableArray *)searchImageMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size;


//搜索视频消息
-(NSMutableArray *)searchVideoMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size;


//搜索语音消息
-(NSMutableArray *)searchVoiceMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size;


//获取未读消息的数量
-(int)getUnReadSessionMessageCountBySessionId:(NSString*)sessionId;

@end

NS_ASSUME_NONNULL_END
