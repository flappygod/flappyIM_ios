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



@end
