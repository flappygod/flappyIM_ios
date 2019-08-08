//
//  PostTool.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

//登录之后非正常关闭
typedef void(^FlappyDead) (void);

//请求失败
typedef void(^FlappyFailure) (NSError *_Nullable,NSInteger);

//请求成功
typedef void(^FlappySuccess) (id _Nullable);


NS_ASSUME_NONNULL_BEGIN

@interface PostTool : NSObject

+(void)postRequest:(NSString*)url
    withParameters:(NSDictionary *)param
       withSuccess:(FlappySuccess)success
       withFailure:(FlappyFailure)failure;

@end

NS_ASSUME_NONNULL_END
