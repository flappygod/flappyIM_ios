//
//  FlappyIM.m
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import "FlappyIM.h"
#import "ApiConfig.h"
#import "User.h"
#import "MJExtension.h"
#import <AFNetworking/AFNetworking.h>

@implementation FlappyIM

//使用单例模式
+ (instancetype)shareInstance {
    static FlappyIM *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        _sharedSingleton = [[super allocWithZone:NULL] init];
    });
    return _sharedSingleton;
}


//请求接口
-(void)postRequest:(NSString*)url
    withParameters:(NSDictionary *)param
       withSuccess:(FlappySuccess)success
       withFailure:(FlappyFailure)failure{
    
    
    //初始化一个AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //设置请求体数据为json类型
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
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


// 防止外部调用alloc或者new
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [FlappyIM shareInstance];
}

// 防止外部调用copy
- (id)copyWithZone:(nullable NSZone *)zone {
    return [FlappyIM shareInstance];
}

// 防止外部调用mutableCopy
- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [FlappyIM shareInstance];
}

//创建账号
-(void)createAccount:(NSString*)userID
         andUserName:(NSString*)userName
         andUserHead:(NSString*)userHead
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure{
    
    //注册地址
    NSString *urlString = URL_register;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userExtendID":userID,
                                 @"userName":userName,
                                 @"userHead":userHead
                                 };
    
    //请求数据
    [self postRequest:urlString
       withParameters:parameters
          withSuccess:success
          withFailure:failure];
    
}



//登录账号
-(void)login:(NSString*)userExtendID
  andSuccess:(FlappySuccess)success
  andFailure:(FlappyFailure)failure{
    //注册地址
    NSString *urlString = URL_login;
    //请求体，参数（NSDictionary 类型）
    NSDictionary *parameters = @{@"userID":@"",
                                 @"userExtendID":userExtendID,
                                 @"device":DEVICE_TYPE,
                                 @"pushid":@"123456789",
                                 };
    //请求数据
    [self postRequest:urlString
       withParameters:parameters
          withSuccess:^(id data) {
              
              //得到当前的用户数据
              NSDictionary* dic=data[@"user"];
              //用户
              User* user=[User mj_objectWithKeyValues:dic];
              
              NSLog(@"%@",user.userId);
              
              
              
          } withFailure:failure];
}



@end
