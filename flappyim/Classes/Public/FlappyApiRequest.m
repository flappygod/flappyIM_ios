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




//执行请求
+(void)postRequest:(NSString*)url
    withParameters:(NSDictionary *)param
       withSuccess:(FlappySuccess)success
       withFailure:(FlappyFailure)failure{
    if([url hasPrefix:@"https"]){
        [FlappyApiRequest postHttps:url withParameters:param withSuccess:success withFailure:failure];
    }else {
        [FlappyApiRequest postHttp:url withParameters:param withSuccess:success withFailure:failure];
    }
}


//请求HTTP
+(void)postHttp:(NSString*)url
 withParameters:(NSDictionary *)param
    withSuccess:(FlappySuccess)success
    withFailure:(FlappyFailure)failure{
    //开始请求
    LXHttpRequest* req=[[LXHttpRequest alloc]init];
    //请求成功的回调
    req.successBlock=^(NSString*  data){
        NSDictionary* responseObject=[FlappyJsonTool JSONStringToDictionary:data];
        //请求成功
        if(responseObject!=nil&&[responseObject[@"resultCode"] integerValue]==RESULT_SUCCESS){
            //数据请求成功
            success(responseObject[@"resultData"]);
        }else{
            //消息
            NSString* resultStr=responseObject[@"resultMessage"];
            //返回代码
            NSString* resultCode=[FlappyStringTool toUnNullZeroStr:responseObject[@"resultCode"]];
            //请求失败
            failure([[NSError alloc]initWithDomain:[FlappyStringTool toUnNullStr:resultStr]
                                              code:RESULT_FAILURE
                                          userInfo:nil],[resultCode integerValue]);
        }
    };
    //失败
    req.errorBlock=^(NSException*  exception){
        //网络错误请求失败
        if(failure!=nil){
            NSError* error=[[NSError alloc]initWithDomain:[FlappyStringTool toUnNullStr:exception.description]
                                                     code:RESULT_NETERROR
                                                 userInfo:nil];
            failure(error,RESULT_NETERROR);
        }
    };
    //参数
    req.params=[param mutableCopy];
    //请求地址
    req.url=url;
    //进行post
    [req postAsParam];
}

//请求HTTPS
+(void)postHttps:(NSString*)url
  withParameters:(NSDictionary *)param
     withSuccess:(FlappySuccess)success
     withFailure:(FlappyFailure)failure{
    //开始请求
    LXHttpsRequest* req=[[LXHttpsRequest alloc]init];
    //请求成功的回调
    req.successBlock=^(NSString*  data){
        NSDictionary* responseObject=[FlappyJsonTool JSONStringToDictionary:data];
        //请求成功
        if(responseObject!=nil&&[responseObject[@"resultCode"] integerValue]==RESULT_SUCCESS){
            //数据请求成功
            success(responseObject[@"resultData"]);
        }else{
            //消息
            NSString* resultStr=responseObject[@"resultMessage"];
            //返回代码
            NSString* resultCode=[FlappyStringTool toUnNullZeroStr:responseObject[@"resultCode"]];
            //请求失败
            failure([[NSError alloc]initWithDomain:[FlappyStringTool toUnNullStr:resultStr]
                                              code:RESULT_FAILURE
                                          userInfo:nil],[resultCode integerValue]);
        }
    };
    //失败
    req.errorBlock=^(NSException*  exception){
        //网络错误请求失败
        if(failure!=nil){
            NSError* error=[[NSError alloc]initWithDomain:[FlappyStringTool toUnNullStr:exception.description]
                                                     code:RESULT_NETERROR
                                                 userInfo:nil];
            failure(error,RESULT_NETERROR);
        }
    };
    //参数
    req.params=[param mutableCopy];
    //请求地址
    req.url=url;
    //进行post
    [req postAsParam];
}





/** 获取data数据的内容长度和头部长度: index --> 头部占用长度 (头部占用长度1-4个字节) */
+ (int32_t)getContentLength:(NSData *)data withHeadLength:(int32_t *)index{
    int8_t tmp = [self readRawByte:data headIndex:index];
    if (tmp >= 0) return tmp;
    int32_t result = tmp & 0x7f;
    if ((tmp = [self readRawByte:data headIndex:index]) >= 0) {
        result |= tmp << 7;
    } else {
        result |= (tmp & 0x7f) << 7;
        if ((tmp = [self readRawByte:data headIndex:index]) >= 0) {
            result |= tmp << 14;
        } else {
            result |= (tmp & 0x7f) << 14;
            if ((tmp = [self readRawByte:data headIndex:index]) >= 0) {
                result |= tmp << 21;
            } else {
                result |= (tmp & 0x7f) << 21;
                result |= (tmp = [self readRawByte:data headIndex:index]) << 28;
                if (tmp < 0) {
                    for (int i = 0; i < 5; i++) {
                        if ([self readRawByte:data headIndex:index] >= 0) {
                            return result;
                        }
                    }
                    result = -1;
                }
            }
        }
    }
    return result;
}

/** 读取字节 */
+ (int8_t)readRawByte:(NSData *)data headIndex:(int32_t *)index{
    if (*index >= data.length) return -1;
    *index = *index + 1;
    return ((int8_t *)data.bytes)[*index - 1];
}


@end
