//
//  LXHttpRequest.m
//  Istudy
//
//  Created by macbook air on 16/7/10.
//  Copyright © 2016年 lipo. All rights reserved.
//

#import "LXHttpRequest.h"
#import "FlappyJsonTool.h"
#import "FlappyData.h"
#import "FlappyIM.h"
#import "RSATool.h"
#import "Aes128.h"

//当前版本
#define FSystemVersion          ([[[UIDevice currentDevice] systemVersion] floatValue])
#define DSystemVersion          ([[[UIDevice currentDevice] systemVersion] doubleValue])
#define SSystemVersion          ([[UIDevice currentDevice] systemVersion])

@implementation LXHttpRequest

//以json形式进行post
-(void)postAsJson{
    NSMutableURLRequest* req=[self getJsonPostRequest];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:req
                                                    completionHandler:^(NSData * _Nullable data,
                                                                        NSURLResponse * _Nullable response,
                                                                        NSError * _Nullable error) {
        //请求成功
        if (error == nil) {
            //检查HTTP响应状态码
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            
            if (statusCode == 200) {
                // 请求成功，处理返回数据
                NSString* resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (self.dataKey != nil) {
                    resultStr = [Aes128 AES128Decrypt:resultStr withKey:self.dataKey];
                }
                [self performSelectorOnMainThread:@selector(dataSuccess:)
                                       withObject:resultStr
                                    waitUntilDone:YES];
            }else{
                //状态401
                if (statusCode == 401){
                    [[FlappyIM shareInstance] setKickedOut];
                }
                //处理其他HTTP错误
                NSString *errorMessage = [NSString stringWithFormat:@"HTTP Error: %ld", (long)statusCode];
                NSError *httpError = [NSError errorWithDomain:@"HTTPErrorDomain"
                                                         code:statusCode
                                                     userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                [self performSelectorOnMainThread:@selector(dataError:)
                                       withObject:httpError
                                    waitUntilDone:YES];
            }
        }
        //请求失败，处理错误
        else {
            [self performSelectorOnMainThread:@selector(dataError:)
                                   withObject:error
                                waitUntilDone:YES];
        }
    }];
    [postDataTask resume];
}


//获取请求
-(NSMutableURLRequest*)getJsonPostRequest{
    //第一步，创建url
    NSURL *url = [NSURL URLWithString:self.url];
    //第二步，创建请求
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc]initWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:self.timeOut];
    //超时时间
    [req setTimeoutInterval: self.timeOut ==0? 60:self.timeOut];
    //是否启用cookie
    [req setHTTPShouldHandleCookies:self.enableCookie];
    //设置post
    [req setHTTPMethod:@"POST"];
    //json格式
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //添加header
    if(self.headerProperty!=nil){
        NSEnumerator *keyEnum = [self.headerProperty keyEnumerator];
        id key;
        while (key = [keyEnum nextObject]) {
            [req setValue:[self.headerProperty valueForKey:key] forHTTPHeaderField:key];
        }
    }
    //添加Uuid
    if(self.dataUuid!=nil){
        [req setValue:self.dataUuid forHTTPHeaderField:@"dataUuid"];
    }
    
    //数据key
    if(self.dataKey!=nil){
        NSString* rsaKey = [[FlappyData shareInstance] getRsaPublicKey];
        if(rsaKey!=nil){
            [req setValue:[RSATool encryptWithPublicKey:rsaKey withData:self.dataKey] forHTTPHeaderField:@"dataKey"];
        }else{
            [req setValue:self.dataKey forHTTPHeaderField:@"dataKey"];
        }
    }
    
    //增加鉴权
    NSString* authToken = [[FlappyData shareInstance] getAuthToken];
    if(authToken!=nil){
        [req setValue:[Aes128 AES128Encrypt:authToken withKey:self.dataKey] forHTTPHeaderField:@"dataToken"];
    }
    
    
    //设置为post请求
    if(self.params==nil){
        self.params = [[NSMutableDictionary alloc]init];
    }
    NSString *requestBodyStr = [FlappyJsonTool JSONObjectToJSONString:self.params];
    //加密
    if(self.dataKey!=nil){
        requestBodyStr = [Aes128 AES128Encrypt:requestBodyStr withKey:self.dataKey];
    }
    NSData *postData = [requestBodyStr dataUsingEncoding:NSUTF8StringEncoding];
    [req setHTTPBody:postData];
    return req;
}


//请求完成
-(void)dataSuccess:(id) data{
    if(_successBlock!=nil)
    {
        _successBlock(data);
    }
}

//请求错误
-(void)dataError:(NSError*) data{
    if(_errorBlock!=nil)
    {
        _errorBlock(data);
    }
}


@end
