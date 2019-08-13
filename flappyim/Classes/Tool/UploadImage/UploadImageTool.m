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
        if(extension==nil){
            extension=@"png";
        }
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






@end
