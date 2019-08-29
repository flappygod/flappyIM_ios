//
//  FlappyBlocks.h
//  Pods
//
//  Created by lijunlin on 2019/8/29.
//

#import "ChatMessage.h"

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
typedef void(^MessageListener) (ChatMessage* _Nullable message);

//会话
typedef void(^SessionListener)(id _Nullable chatsession);

#endif /* FlappyBlocks_h */
