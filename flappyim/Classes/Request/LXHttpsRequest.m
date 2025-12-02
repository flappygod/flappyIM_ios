//
//  LXHttpsRequest.m
//  zhichuangyanbao
//
//  Created by macbook air on 16/12/16.
//  Copyright © 2016年 zhichuangyanbao. All rights reserved.
//

#import "LXHttpsRequest.h"
#import "FlappyJsonTool.h"
#import "FlappyData.h"
#import "FlappyIM.h"
#import "RSATool.h"
#import "Aes128.h"

//当前版本
#define FSystemVersion          ([[[UIDevice currentDevice] systemVersion] floatValue])
#define DSystemVersion          ([[[UIDevice currentDevice] systemVersion] doubleValue])
#define SSystemVersion          ([[UIDevice currentDevice] systemVersion])

@implementation LXHttpsRequest

//以json形式进行post
-(void)postAsJson{
    //创建request
    NSMutableURLRequest* req=[self getJsonPostRequest];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
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
            }  else {
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
    //设置为post方式
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
    NSString *requestBodyStr = [FlappyJsonTool jsonObjectToJsonStr:self.params];
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
-(void)dataError:(id) data{
    if(_errorBlock!=nil)
    {
        _errorBlock(data);
    }
}

//解压p12数据
-(OSStatus) extractP12Data:(CFDataRef)inP12Data
              withPassword:(NSString*)passstr
                toIdentity:(SecIdentityRef*)identity {
    
    OSStatus securityError = errSecSuccess;
    CFStringRef password = (__bridge CFStringRef)passstr;
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import(inP12Data, options, &items);
    
    if (securityError == 0) {
        CFDictionaryRef ident = CFArrayGetValueAtIndex(items,0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(ident, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
    }
    
    if (options) {
        CFRelease(options);
    }
    
    return securityError;
}

#pragma NSURLSessionDelegate

/* The last message a session receives.  A session will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case the error parameter will be nil.
 */
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
    NSLog(@"%@",error.description);
}

/* If implemented, when a connection level authentication challenge
 * has occurred, this delegate will be given the opportunity to
 * provide authentication credentials to the underlying
 * connection. Some types of authentication will apply to more than
 * one request on a given connection to a server (SSL Server Trust
 * challenges).  If this delegate message is not implemented, the
 * behavior will be to use the default handling, which may involve user
 * interaction.
 */
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    //获取验证的类型
    NSString *method = challenge.protectionSpace.authenticationMethod;
    
    //如果是服务器验证
    if([method isEqualToString:NSURLAuthenticationMethodServerTrust]){
        //获取host
        //NSString *host = challenge.protectionSpace.host;
        //创建证书
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        //安装证书
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        return;
    }
    
    //如果是验证本地的
    
    //本地的密码
    NSString* password=@"";
    //本地的资源文件名称
    NSString* resourceName=@"";
    //p12文件
    NSString *thePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"p12"];
    //p12数据
    NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:thePath];
    //retain
    CFDataRef inPKCS12Data = (CFDataRef)CFBridgingRetain(PKCS12Data);
    
    SecIdentityRef identity;
    
    // 读取p12证书中的内容
    OSStatus result = [self extractP12Data:inPKCS12Data
                              withPassword:password
                                toIdentity:&identity];
    //读取不成功
    if(result != errSecSuccess){
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }
    
    //读取成功
    SecCertificateRef certificate = NULL;
    //赋值
    SecIdentityCopyCertificate (identity, &certificate);
    
    const void *certs[] = {certificate};
    
    CFArrayRef certArray = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);
    
    //创建证书
    NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity
                                                             certificates:(NSArray*)CFBridgingRelease(certArray)
                                                              persistence:NSURLCredentialPersistencePermanent];
    //返回过去
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    
}

/* If an application has received an
 * -application:handleEventsForBackgroundURLSession:completionHandler:
 * message, the session delegate will receive this message to indicate
 * that all messages previously enqueued for this session have been
 * delivered.  At this time it is safe to invoke the previously stored
 * completion handler, or to begin any internal updates that will
 * result in invoking the completion handler.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session NS_AVAILABLE_IOS(7_0){
    
    
}




@end
