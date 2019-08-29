//
//  PostTool.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "FlappyChatSession.h"
#import "ChatMessage.h"

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
typedef void(^SessionListener) (FlappyChatSession* _Nullable session);

NS_ASSUME_NONNULL_BEGIN

@interface FlappyApiRequest : NSObject

//请求数据
+(void)postRequest:(NSString*)url
    withParameters:(NSDictionary *)param
       withSuccess:(FlappySuccess)success
       withFailure:(FlappyFailure)failure;

//获取data数据的内容长度和头部长度: index --> 头部占用长度 (头部占用长度1-4个字节)
+ (int32_t)getContentLength:(NSData *)data
             withHeadLength:(int32_t *)index;

//读取字节
+ (int8_t)readRawByte:(NSData *)data
            headIndex:(int32_t *)index;


@end

NS_ASSUME_NONNULL_END
