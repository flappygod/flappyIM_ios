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

//生成UUID
+(NSString *)generateUUID;

//生成随机字符串
+(NSString*)generateRandomStr:(NSInteger)length;

//请求数据
+(void)postRequest:(NSString*)url
    withParameters:(NSDictionary *)param
       withSuccess:(FlappySuccess)success
       withFailure:(FlappyFailure)failure;




@end

NS_ASSUME_NONNULL_END
