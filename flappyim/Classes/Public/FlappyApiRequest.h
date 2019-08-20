//
//  PostTool.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "ChatMessage.h"

//消息通知被点击
typedef void(^NotificateClick) (ChatMessage*_Nullable message);

//被踢下线了
typedef void(^FlappyKnicked) (void);

//登录之后非正常关闭
typedef void(^FlappyDead) (void);

//请求失败
typedef void(^FlappyFailure) (NSError *_Nullable,NSInteger);

//请求成功
typedef void(^FlappySuccess) (id _Nullable);

//消息监听
typedef void(^MessageListener) (ChatMessage* _Nullable message);


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
