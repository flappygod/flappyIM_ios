//
//  UploadImageTool.m
//  driver
//
//  Created by macbook air on 16/8/5.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import "UploadImageTool.h"
#import "StringTool.h"
#import <AFNetworking/AFNetworking.h>


@implementation UploadImageTool



//上传图片和视频
- (void)uploadImageAndMovieBaseModel:(NSString*)urlPath
                            andModel:(UploadModel *)model {
    
    //文件名
    NSString *fileName = [model.path componentsSeparatedByString:@"/"].lastObject;
    
    //设置mimeType
    NSString *mimeType;
    if ([model.type isEqualToString:@"image"]) {
        //获取文件的后缀名
        if([model.path rangeOfString:@"."].location!=NSNotFound){
            NSString *extension = [model.path componentsSeparatedByString:@"."].lastObject;
            mimeType = [NSString stringWithFormat:@"image/%@", extension];
        }else{
            //图片默认png
            NSString *extension = @"png";
            mimeType = [NSString stringWithFormat:@"image/%@", extension];
        }
        
    } else {
        //获取文件的后缀名
        if([model.path rangeOfString:@"."].location!=NSNotFound){
            NSString *extension = [model.path componentsSeparatedByString:@"."].lastObject;
            mimeType = [NSString stringWithFormat:@"video/%@", extension];
        }else{
            //音频默认MOV文件
            NSString *extension = @"MOV";
            mimeType = [NSString stringWithFormat:@"video/%@", extension];
        }
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
                                                          reason:[StringTool toUnNullStr:error.description]
                                                        userInfo:nil]);
        }
    }];
}






@end
