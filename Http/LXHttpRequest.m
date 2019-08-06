//
//  LXHttpRequest.m
//  Istudy
//
//  Created by macbook air on 16/7/10.
//  Copyright © 2016年 lipo. All rights reserved.
//

#import "LXHttpRequest.h"
#import "CommonDef.h"
#import "JsonTool.h"


@implementation LXHttpRequest
{
    //cookie
    //NSHTTPCookieStorage *cookieJar;
}



//同步get请求
-(NSString*)syncGet:(NSError*)error{
    //空的不执行
    if(self.url==nil){
        return nil;
    }
    NSMutableURLRequest* request=[self getParamGetRequest];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
#pragma clang diagnostic pop
    NSString *str = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
    if(error!=nil&&![error isEqual:[NSNull null]])
    {
        return str;
    }
    return nil;
}

//同步发送post请求
-(NSString*)syncPostAsJson:(NSError*)error{
    //空的不执行
    if(self.url==nil){
        return nil;
    }
    NSMutableURLRequest* request=[self getJsonPostRequest];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
#pragma clang diagnostic pop
    NSString *str = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
    if(error!=nil&&![error isEqual:[NSNull null]])
    {
        return str;
    }
    return nil;
}

//同步发送param形式的数据
-(NSString*)syncPostAsParam:(NSError*)error{
    //空的不执行
    if(self.url==nil){
        return nil;
    }
    NSMutableURLRequest* request=[self getParamPostRequest];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
#pragma clang diagnostic pop
    NSString *str = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
    if(error!=nil&&![error isEqual:[NSNull null]])
    {
        return str;
    }
    return nil;
}




//下方属于异步操作



//直接get
-(void)get{
    //空的不执行
    if(self.url==nil){
        return;
    }
    NSMutableURLRequest* request=[self getParamGetRequest];
    //低于九点0版本使用这个
    if(DSystemVersion<7.0)
    {
        // NSURLConnection* aSynConnection 可以申明为全局变量.
        // 在协议方法中，通过判断aSynConnection，来区分，是哪一个异步请求的返回数据。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSURLConnection * ret=[[NSURLConnection alloc] initWithRequest:request delegate:self];
        NSLog(@"%@",ret);
#pragma clang diagnostic pop
        
    }else{
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if(error==nil){
                NSString* resultStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                [self performSelectorOnMainThread:@selector(dataSuccess:) withObject:resultStr waitUntilDone:YES];
                
            }else{
                [self performSelectorOnMainThread:@selector(dataError:) withObject:error waitUntilDone:YES];
            }
        }];
        [postDataTask resume];
    }
}

//以json形式进行post
-(void)postAsJson{
    NSMutableURLRequest* req=[self getJsonPostRequest];
    if(DSystemVersion<7.0){
        //第三步，连接服务器
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:req delegate:self];
        NSLog(@"%@",connection);
#pragma clang diagnostic pop
    }else{
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if(error==nil){
                NSString* resultStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                [self performSelectorOnMainThread:@selector(dataSuccess:) withObject:resultStr waitUntilDone:YES];
            }else{
                [self performSelectorOnMainThread:@selector(dataError:) withObject:error waitUntilDone:YES];
            }
        }];
        [postDataTask resume];
    }
}

//以param形式进行post
-(void)postAsParam{
    //获取post
    NSMutableURLRequest* req=[self getParamPostRequest];
    if(DSystemVersion<7.0){
        //第三步，连接服务器
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:req delegate:self];
        NSLog(@"%@",connection);
#pragma clang diagnostic pop
    }else{
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if(error==nil){
                NSString* resultStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                [self performSelectorOnMainThread:@selector(dataSuccess:) withObject:resultStr waitUntilDone:YES];
            }else{
                [self performSelectorOnMainThread:@selector(dataError:) withObject:error waitUntilDone:YES];
            }
        }];
        [postDataTask resume];
    }
}


//get请求的情况下获取request
-(NSMutableURLRequest*)getParamGetRequest{
    //拼接支付穿
    NSString *paramString;
    if(self.params!=nil)
    {
        paramString=[NSString stringWithFormat:@"%@?%@",self.url,[self parseParams:_params]];
    }else{
        paramString=self.url;
    }
    NSString *urlString=paramString;
    //特殊处理
    if(DSystemVersion<7.0)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
#pragma clang diagnostic pop
    }
    else{
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString: urlString]];
    //禁止cachedata
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    //超时时间
    [request setTimeoutInterval: self.timeOut ==0? 60:self.timeOut];
    //是否启用cookie
    [request setHTTPShouldHandleCookies:self.enableCookie];
    //设置get模式
    [request setHTTPMethod:@"GET"];
    
    //添加header
    if(self.headerProperty!=nil){
        NSEnumerator *keyEnum = [self.headerProperty keyEnumerator];
        id key;
        while (key = [keyEnum nextObject]) {
            [request setValue:[self.headerProperty valueForKey:key] forHTTPHeaderField:key];
        }
    }
    return request;
}

//获取请求
-(NSMutableURLRequest*)getJsonPostRequest{
    //第一步，创建url
    NSURL *url = [NSURL URLWithString:self.url];
    //第二步，创建请求
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.timeOut];
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
    //设置为post请求
    if (self.params != nil )
    {
        NSString *parseParamsResult = [JsonTool JSONObjectToJSONString:self.params];
        NSData *postData = [parseParamsResult dataUsingEncoding:NSUTF8StringEncoding];
        [req setHTTPBody:postData];
    }
    return req;
}

//获取param形式的post
-(NSMutableURLRequest*)getParamPostRequest{
    //第一步，创建url
    NSURL *url = [NSURL URLWithString:self.url];
    //第二步，创建请求
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.timeOut];
    //超时时间
    [req setTimeoutInterval: self.timeOut ==0? 60:self.timeOut];
    //是否启用cookie
    [req setHTTPShouldHandleCookies:self.enableCookie];
    //设置post
    [req setHTTPMethod:@"POST"];
    //添加header
    if(self.headerProperty!=nil){
        NSEnumerator *keyEnum = [self.headerProperty keyEnumerator];
        id key;
        while (key = [keyEnum nextObject]) {
            [req setValue:[self.headerProperty valueForKey:key] forHTTPHeaderField:key];
        }
    }
    //设置为post请求
    if (self.params != nil )
    {
        NSString *parseParamsResult = [self parseParams:self.params];
        NSData *postData = [parseParamsResult dataUsingEncoding:NSUTF8StringEncoding];
        [req setHTTPBody:postData];
    }
    return req;
}


//把NSDictionary解析成post格式的NSString字符串
- (NSString *)parseParams:(NSDictionary *)params{
    NSString *keyValueFormat;
    NSMutableString *result = [NSMutableString new];
    //实例化一个key枚举器用来存放dictionary的key
    NSEnumerator *keyEnum = [params keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        keyValueFormat = [NSString stringWithFormat:@"%@=%@&",key,[params valueForKey:key]];
        [result appendString:keyValueFormat];
    }
    NSString* paramStr=@"";
    if(result.length>1){
        paramStr=[result substringWithRange:NSMakeRange(0, result.length-1)];
        NSLog(@"post()方法参数解析结果：%@",paramStr);
    }
    return paramStr;
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
        NSError* erro=data;
        NSException* excep=[[NSException alloc]initWithName:@"neterror"
                                                     reason:erro.description
                                                   userInfo:erro.userInfo];
        _errorBlock(excep);
    }
}



#pragma NSURLConnectionDelegate

//接收到服务器回应的时候调用此方法
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    //获取headerfields
    //原生NSURLConnection写法
    //NSDictionary *fields = [res allHeaderFields];
    
    //获取cookie方法1
    // NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:fields forURL:url];
    //获取cookie方法2
    //NSString *cookieString = [[HTTPResponse allHeaderFields] valueForKey:@"Set-Cookie"];
    //获取cookie方法3
    //cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    self.receiveData = [NSMutableData data];
}

//接收到服务器传输数据的时候调用，此方法根据数据大小执行若干次
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receiveData appendData:data];
}

//数据传完之后调用此方法
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *receiveStr = [[NSString alloc]initWithData:self.receiveData
                                                encoding:NSUTF8StringEncoding];
    //结束
    if(self.successBlock!=nil)
    {
        NSString *resultStr = [[NSString alloc]initWithData:self.receiveData
                                                   encoding:NSUTF8StringEncoding];
        self.successBlock(resultStr);
    }    NSLog(@"%@",receiveStr);
}

//网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error

{
    if(self.errorBlock!=nil){
        NSException* exception=[[NSException alloc]initWithName:@"neterror"
                                                         reason:error.description
                                                       userInfo:nil];
        self.errorBlock(exception);
    }
}


- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//IOS9.0以下使用https的时候安全验证，这里默认是通过
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

//IOS9.0以下使用https的时候安全验证，这里默认是通过
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"didReceiveAuthenticationChallenge %@ %zd", [[challenge protectionSpace] authenticationMethod], (ssize_t) [challenge previousFailureCount]);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        NSLog(@"%@",challenge.protectionSpace.host);
        [[challenge sender]  useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
    }
}
#pragma clang diagnostic pop



@end
