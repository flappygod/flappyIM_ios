//
//  PostTool.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import "PostTool.h"
#import "ApiConfig.h"

@implementation PostTool


//请求接口
+(void)postRequest:(NSString*)url
    withParameters:(NSDictionary *)param
       withSuccess:(FlappySuccess)success
       withFailure:(FlappyFailure)failure{
    
    
    //初始化一个AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //设置请求体数据为json类型
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    //设置响应体数据为json类型
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    //请求数据
    [manager POST:url
       parameters:param
         progress:^(NSProgress * _Nonnull uploadProgress) {
             
         } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             //请求成功
             if(responseObject!=nil&&[responseObject[@"resultCode"] integerValue]==1){
                 //数据请求成功
                 success(responseObject[@"resultData"]);
             }else{
                 //请求失败
                 failure([[NSError alloc]initWithDomain:responseObject[@"resultMessage"]
                                                   code:RESULT_FAILURE
                                               userInfo:nil],
                         RESULT_FAILURE);
             }
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             //网络错误请求失败
             failure(error,RESULT_NETERROR);
         }];
}


@end
