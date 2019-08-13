//
//  UploadImageTool.m
//  driver
//
//  Created by macbook air on 16/8/5.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import "UploadImageTool.h"
#import <AFNetworking/AFNetworking.h>


@implementation UploadImageTool



//上传图片和视频
- (void)uploadImageAndMovieBaseModel:(NSString*)urlPath
                            andModel:(UploadModel *)model {
    
    //获取文件的后缀名
    NSString *extension = [model.name componentsSeparatedByString:@"."].lastObject;
    //文件名
    NSString *fileName = [model.name componentsSeparatedByString:@"/"].lastObject;
    
    //设置mimeType
    NSString *mimeType;
    if ([model.type isEqualToString:@"image"]) {
        mimeType = [NSString stringWithFormat:@"image/%@", extension];
    } else {
        mimeType = [NSString stringWithFormat:@"video/%@", extension];
    }
    //创建AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //设置响应文件类型为JSON类型
    manager.responseSerializer    = [AFJSONResponseSerializer serializer];
    
    //初始化requestSerializer
    manager.requestSerializer     = [AFHTTPRequestSerializer serializer];
    
    manager.responseSerializer.acceptableContentTypes = nil;
    
    //设置timeout
    [manager.requestSerializer setTimeoutInterval:20.0];
    
    //设置请求头类型
    [manager.requestSerializer setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    
    //防止循环引用
    __weak typeof(self) safeSelf=self;
    //开始上传
    [manager POST:urlPath parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError *error;
        BOOL success = [formData appendPartWithFileURL:[NSURL fileURLWithPath:model.path]
                                                  name:model.name
                                              fileName:fileName
                                              mimeType:mimeType
                                                 error:&error];
        if (!success) {
            if(safeSelf.errorBlock!=nil)
            {
                safeSelf.errorBlock([[NSException alloc]initWithName:@"upload error"
                                                              reason:error.description
                                                            userInfo:nil]);
            }
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        //结束
        if(safeSelf.successBlock!=nil)
        {
            safeSelf.successBlock(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //结束
        if(safeSelf.errorBlock!=nil)
        {
            safeSelf.errorBlock([[NSException alloc]initWithName:@"upload error"
                                                          reason:error.description
                                                        userInfo:nil]);
        }
    }];
}




//上传图片到服务器
-(void)uploadFiles:(NSString*)urlPath
        andMParams:(NSMutableDictionary*)params
           andFile:(NSMutableDictionary*)images{
    
    NSString* PREFIX = @"--"; // 前缀
    NSString* LINE_END = @"\r\n";     // 边界标识
    NSString* BOUNDARY =  @"AaB03x";
    
    //根据url初始化request
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlPath]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:60];
    
    
    //http body的字符串
    NSMutableString *parambody=[[NSMutableString alloc]init];
    //参数的集合的所有key的集合
    NSArray *keys= [params allKeys];
    
    //遍历keys
    for(int i=0;i<[keys count];i++)
    {
        //得到当前key
        NSString *key=[keys objectAtIndex:i];
        //如果key不是pic，说明value是字符类型，比如name：Boris
        //添加分界线，换行
        [parambody appendFormat:@"%@%@%@",PREFIX,BOUNDARY,LINE_END];
        //添加字段名称，换2行
        [parambody appendFormat:@"Content-Disposition:form-data;name=\"%@\"\r\n\r\n",key];
        //添加字段的值
        [parambody appendFormat:@"%@\r\n",[params objectForKey:key]];
    }
    
    //声明myRequestData，用来放入http body
    NSMutableData *myRequestData=[NSMutableData data];
    //将body字符串转化为UTF8格式的二进制
    [myRequestData appendData:[parambody dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    NSArray *imagesKeys= [images allKeys];
    //遍历keys
    for(int i=0;i<[imagesKeys count];i++)
    {
        //http body的字符串
        NSMutableString *imbody=[[NSMutableString alloc]init];
        //得到当前key
        NSString *key=[imagesKeys objectAtIndex:i];
        ////添加分界线，换行
        [imbody appendFormat:@"%@%@%@",PREFIX,BOUNDARY,LINE_END];
        //声明pic字段，文件名为boris.png
        [imbody appendFormat:@"Content-Disposition:form-data;name=\"%@\";filename=\"%@.png\"\r\n",key,key];
        //声明上传文件的格式
        [imbody appendFormat:@"Content-Type:multipart/form-data\r\n\r\n"];
        UIImage* image=[images objectForKey:key];
        //将image的data加入
        NSData* data = UIImagePNGRepresentation(image);
        [myRequestData appendData:[imbody dataUsingEncoding:NSUTF8StringEncoding]];
        [myRequestData appendData:data];
        [myRequestData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    //声明结束符：--AaB03x--
    NSString *end=[[NSString alloc]initWithFormat:@"%@%@%@%@",PREFIX,BOUNDARY,PREFIX,LINE_END];
    [myRequestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    //加入
    {
        [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
        [request setValue:@"utf-8" forHTTPHeaderField:@"Charset"];
        [request setValue:@"keep-alive" forHTTPHeaderField:@"connection"];
        [request setValue:@"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)" forHTTPHeaderField:@"user-agent"];
        NSString*  contentType=[NSString stringWithFormat:@"multipart/form-data;boundary=%@",BOUNDARY];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    }
    
    //设置http body
    [request setHTTPBody:myRequestData];
    //http method
    [request setHTTPMethod:@"POST"];
    
    //建立连接，设置代理
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    NSLog(@"%@",conn);
}





#pragma NSURLConnectionDelegate

//接收到服务器回应的时候调用此方法
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    NSLog(@"%@",[res allHeaderFields]);
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
    NSString *receiveStr = [[NSString alloc]initWithData:self.receiveData encoding:NSUTF8StringEncoding];
    //结束
    if(self.successBlock!=nil)
    {
        NSString *resultStr = [[NSString alloc]initWithData:self.receiveData
                                                   encoding:NSUTF8StringEncoding];
        self.successBlock(resultStr);
    }    NSLog(@"%@",receiveStr);
}

//网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
-(void)connection:(NSURLConnection *)connection
 didFailWithError:(NSError *)error

{
    if(self.errorBlock!=nil){
        self.errorBlock([[NSException alloc]initWithName:@"upload error" reason:error.description userInfo:nil]);
    }
    NSLog(@"%@",[error localizedDescription]);
}

//IOS9.0以下使用https的时候安全验证，这里默认是通过
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"didReceiveAuthenticationChallenge %@ %zd", [[challenge protectionSpace] authenticationMethod], (ssize_t) [challenge previousFailureCount]);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        NSLog(@"%@",challenge.protectionSpace.host);
        [[challenge sender]  useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
        
    }
}





@end
