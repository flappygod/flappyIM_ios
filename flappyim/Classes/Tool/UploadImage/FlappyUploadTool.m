//
//  UploadImageTool.m
//  driver
//
//  Created by macbook air on 16/8/5.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import "FlappyUploadTool.h"
#import "FlappyStringTool.h"
#import "FlappyApiRequest.h"
#import <AFNetworking/AFNetworking-umbrella.h>


@implementation FlappyUploadTool


//使用单例模式
+(AFHTTPSessionManager*)shareManager {
    static AFHTTPSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        manager = [AFHTTPSessionManager manager];
        
    });
    return manager;
}


//上传图片和视频
- (void)uploadFileBaseModel:(NSString*)urlPath
                            andModel:(FlappyUploadModel *)model {
    NSMutableArray* array=[[NSMutableArray alloc]init];
    [array addObject:model];
    [self uploadFilesBaseModel:urlPath andModels:array];
}



//上传图片和视频
- (void)uploadFilesBaseModel:(NSString*)urlPath
                           andModels:(NSMutableArray *)models {
    
    //创建AFHTTPSessionManager
    AFHTTPSessionManager *manager = [FlappyUploadTool shareManager];
    
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
    
    [manager POST:urlPath parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for(int s=0;s<models.count;s++){
            FlappyUploadModel* model=[models objectAtIndex:s];
            
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
                
                //文件名
                NSString *fileName = [model.path componentsSeparatedByString:@"/"].lastObject;
                //错误
                NSError *error;
                //URL
                NSURL* url;
                //如果以file开头
                if([model.path hasPrefix:@"file://"]){
                    //其实不需要，切掉前面的
                    NSString* path=[model.path substringWithRange:NSMakeRange(7, model.path.length-7)];
                    //创建url
                    url=[NSURL fileURLWithPath:path];
                }else{
                    //创建url
                    url=[NSURL fileURLWithPath:model.path];
                }
                [formData appendPartWithFileURL:url
                                           name:model.name
                                       fileName:fileName
                                       mimeType:mimeType
                                          error:&error];
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
                
                //文件名
                NSString *fileName = [model.path componentsSeparatedByString:@"/"].lastObject;
                //错误
                NSError *error;
                //URL
                NSURL* url;
                //如果以file开头
                if([model.path hasPrefix:@"file://"]){
                    //其实不需要，切掉前面的
                    NSString* path=[model.path substringWithRange:NSMakeRange(7, model.path.length-7)];
                    //创建url
                    url=[NSURL fileURLWithPath:path];
                }else{
                    //创建url
                    url=[NSURL fileURLWithPath:model.path];
                }
                
                [formData appendPartWithFileData:[NSData dataWithContentsOfFile:model.path]
                                            name:model.name
                                        fileName:fileName
                                        mimeType:mimeType];
                
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
                                                          reason:[FlappyStringTool toUnNullStr:error.description]
                                                        userInfo:nil]);
        }
    }];
    
}



@end
