//
//  PostTool.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import "FlappyApiRequest.h"
#import "FlappyStringTool.h"
#import "LXHttpsRequest.h"
#import "FlappyJsonTool.h"
#import "LXHttpRequest.h"
#import "FlappyConfig.h"

@implementation FlappyApiRequest

//定义静态变量
static NSString *dataUuid = nil;
static NSString *dataKey = nil;

//获取dataUuid
+(NSString*)dataUuid{
    if (!dataUuid) {
        dataUuid = [[NSUUID UUID] UUIDString];
    }
    return dataUuid;
}

//获取dataKey
+(NSString*)dataKey{
    if (!dataKey) {
        dataKey = [self generateRandomStr:16];
    }
    return dataKey;
}

//生成UUID的方法
+(NSString *)generateUUID{
    NSUUID *uuid = [NSUUID UUID];
    return [uuid UUIDString];
}

//生成指定长度随机字符串的方法
+(NSString*)generateRandomStr:(NSInteger)length{
    NSString *characters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSInteger i = 0; i < length; i++) {
        NSUInteger index = arc4random_uniform((uint32_t)[characters length]);
        unichar character = [characters characterAtIndex:index];
        [randomString appendFormat:@"%C", character];
    }
    return randomString;
}

//执行请求
+(void)postRequest:(NSString*)url
    withParameters:(NSDictionary *)param
       withSuccess:(FlappySuccess)success
       withFailure:(FlappyFailure)failure{
    if([url hasPrefix:@"https"]){
        [FlappyApiRequest postHttps:url
                           withUUID:[self dataUuid]
                            withKey:[self dataKey]
                     withParameters:param
                        withSuccess:success
                        withFailure:failure];
    }else {
        [FlappyApiRequest postHttp:url 
                          withUUID:[self dataUuid]
                           withKey:[self dataKey]
                    withParameters:param
                       withSuccess:success
                       withFailure:failure];
    }
}

//请求HTTP
+(void)postHttp:(NSString*)url
       withUUID:(NSString*)dataUuid
        withKey:(NSString*)dataKey
 withParameters:(NSDictionary *)param
    withSuccess:(FlappySuccess)success
    withFailure:(FlappyFailure)failure{
    //开始请求
    LXHttpRequest* req=[[LXHttpRequest alloc]init];
    req.dataUuid=dataUuid;
    req.dataKey=dataKey;
    //请求成功的回调
    req.successBlock=^(NSString*  data){
        NSDictionary* responseObject=[FlappyJsonTool JSONStringToDictionary:data];
        //请求成功
        if(responseObject!=nil&&[responseObject[@"code"] integerValue]==RESULT_SUCCESS){
            //数据请求成功
            success(responseObject[@"data"]);
        }else{
            //消息
            NSString* resultStr=responseObject[@"msg"];
            //返回代码
            NSString* resultCode=[FlappyStringTool toUnNullZeroStr:responseObject[@"code"]];
            //请求失败
            failure([[NSError alloc]initWithDomain:[FlappyStringTool toUnNullStr:resultStr]
                                              code:RESULT_FAILURE
                                          userInfo:nil],[resultCode integerValue]);
        }
    };
    req.errorBlock=^(NSError*  error){
        //网络错误请求失败
        if(failure!=nil){
            failure(error,RESULT_NETERROR);
        }
    };
    //参数
    req.params=[param mutableCopy];
    //请求地址
    req.url=url;
    //进行post
    [req postAsJson];
}

//请求HTTPS
+(void)postHttps:(NSString*)url
        withUUID:(NSString*)dataUuid
         withKey:(NSString*)dataKey
  withParameters:(NSDictionary *)param
     withSuccess:(FlappySuccess)success
     withFailure:(FlappyFailure)failure{
    //开始请求
    LXHttpsRequest* req=[[LXHttpsRequest alloc]init];
    req.dataUuid=dataUuid;
    req.dataKey=dataKey;
    //请求成功的回调
    req.successBlock=^(NSString*  data){
        NSDictionary* responseObject=[FlappyJsonTool JSONStringToDictionary:data];
        //请求成功
        if(responseObject!=nil&&[responseObject[@"code"] integerValue]==RESULT_SUCCESS){
            //数据请求成功
            success(responseObject[@"data"]);
        }else{
            //消息
            NSString* resultStr=responseObject[@"msg"];
            //返回代码
            NSString* resultCode=[FlappyStringTool toUnNullZeroStr:responseObject[@"code"]];
            //请求失败
            failure([[NSError alloc]initWithDomain:[FlappyStringTool toUnNullStr:resultStr]
                                              code:RESULT_FAILURE
                                          userInfo:nil],[resultCode integerValue]);
        }
    };
    //失败
    req.errorBlock=^(NSError*  error){
        //网络错误请求失败
        if(failure!=nil){
            failure(error,RESULT_NETERROR);
        }
    };
    //参数
    req.params=[param mutableCopy];
    //请求地址
    req.url=url;
    //进行post
    [req postAsJson];
}

@end
