//
//  PostTool.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking-umbrella.h>
#import "FlappyBlocks.h"
#import "FlappyChatSession.h"
#import "ChatMessage.h"


NS_ASSUME_NONNULL_BEGIN

@interface FlappyApiRequest : NSObject


+ (AFHTTPSessionManager*)shareManager;

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
