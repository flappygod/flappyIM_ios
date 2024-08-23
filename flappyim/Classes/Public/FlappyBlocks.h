//
//  FlappyBlocks.h
//  Pods
//
//  Created by lijunlin on 2019/8/29.
//

#import "ChatMessage.h"
#import "ChatSessionData.h"

#ifndef FlappyBlocks_h
#define FlappyBlocks_h

//消息通知被点击
typedef void(^NotifyClickListener) (ChatMessage*_Nullable message);

//被踢下线了
typedef void(^FlappyKnicked) (void);

//登录之后非正常关闭
typedef void(^FlappyDead) (void);

//请求成功
typedef void(^FlappySuccess) (id _Nullable);

//请求失败
typedef void(^FlappyFailure) (NSError *_Nullable,NSInteger);

//发送消息成功
typedef void(^FlappySendSuccess) (ChatMessage* _Nullable message);

//发送消息失败
typedef void(^FlappySendFailure) (ChatMessage* _Nullable,NSError *_Nullable,NSInteger);

//消息监听
typedef void(^MessageListListener) (NSArray* _Nullable messageList);

//消息监听
typedef void(^MessageListener) (ChatMessage* _Nullable message);

//消息读取监听
typedef void(^MessageReadListener) (NSString* _Nullable  sessionId,NSString* _Nullable  readerId,NSString* _Nullable  tableSeqence);

//消息删除监听
typedef void(^MessageDeleteListener) (NSString* _Nullable  messageId);

//会话列表
typedef void(^SessionListListener)(NSArray* _Nullable sessionList);

//会话
typedef void(^SessionListener)(ChatSessionData* _Nullable session);

#endif /* FlappyBlocks_h */
