//
//  FlappyApiConfig.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/17.
//

#import "FlappyApiConfig.h"
#import "FlappyConfig.h"

@implementation FlappyApiConfig

//使用单例模式
+ (instancetype)shareInstance {
    static FlappyApiConfig *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        _sharedSingleton = [[super allocWithZone:NULL] init];
        //默认12秒
        _sharedSingleton.heartInterval=12;
        //默认6秒
        _sharedSingleton.autoLoginInterval=6;
        //默认正式环境
        _sharedSingleton.pushPlat=@"release";
        //地址
        [_sharedSingleton  resetServer:FLAPPY_BASE andUploadUrl:FLAPPY_BASE];
        
    });
    return _sharedSingleton;
}

// 防止外部调用alloc或者new
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [FlappyApiConfig shareInstance];
}

//设置心跳
-(void)setHeartInterval:(NSInteger)heartInterval{
    _heartInterval=MAX(heartInterval, 3);
}

//自动登录时间间隔
-(void)setAutoLoginInterval:(NSInteger)autoLoginInterval{
    _autoLoginInterval=MAX(autoLoginInterval, 3);
}

// 防止外部调用copy
- (id)copyWithZone:(nullable NSZone *)zone {
    return [FlappyApiConfig shareInstance];
}

// 防止外部调用mutableCopy
- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [FlappyApiConfig shareInstance];
}

//重新设置服务器地址
-(void)resetServer:(NSString*)serverUrl
      andUploadUrl:(NSString*)upload{
    
    //地址
    self.BaseUrl=serverUrl;
    //上传地址
    self.BaseUploadUrl=upload;
    //上传文件的地址
    self.URL_fileUpload= [NSString stringWithFormat:@"%@/upload/fileUpload",self.BaseUploadUrl];
    
    //上传文件的地址
    self.URL_videoUpload= [NSString stringWithFormat:@"%@/upload/videoUpload",self.BaseUploadUrl];
    
    //修改推送ID
    self.URL_changePush= [NSString stringWithFormat:@"%@/api/changePush",self.BaseUploadUrl];
    
    //创建账户
    self.URL_register= [NSString stringWithFormat:@"%@/api/register",self.BaseUrl];
    
    //创建账户
    self.URL_update= [NSString stringWithFormat:@"%@/api/updateUser",self.BaseUrl];
    
    //登录账号
    self.URL_login =[NSString stringWithFormat:@"%@/api/login",self.BaseUrl];
    
    //退出账号
    self.URL_logout= [NSString stringWithFormat:@"%@/api/logout",self.BaseUrl];
    
    //自动登录账号
    self.URL_autoLogin= [NSString stringWithFormat:@"%@/api/autoLogin",self.BaseUrl];
    
    //创建会话
    self.URL_createSingleSession= [NSString stringWithFormat:@"%@/api/createSingleSession",self.BaseUrl];
    
    //获取单聊会话
    self.URL_getSingleSession =[NSString stringWithFormat:@"%@/api/getSingleSession",self.BaseUrl];
    
    //创建多人会话
    self.URL_createGroupSession= [NSString stringWithFormat:@"%@/api/createGroupSession",self.BaseUrl];
    
    //通过sessionExtendID获取会话
    self.URL_getSessionByExtendId =[NSString stringWithFormat:@"%@/api/getSessionByExtendId",self.BaseUrl];
    
    //通过sessionID获取会话
    self.URL_getSessionById =[NSString stringWithFormat:@"%@/api/getSessionById",self.BaseUrl];
    
    //获取当前用户的所有会话
    self.URL_getUserSessionList= [NSString stringWithFormat:@"%@/api/getUserSessionList",self.BaseUrl];
    
    //添加用户到会话
    self.URL_addUserToSession =[NSString stringWithFormat:@"%@/api/addUserToSession",self.BaseUrl];
    
    //删除会话中的用户
    self.URL_delUserInSession= [NSString stringWithFormat:@"%@/api/delUserInSession",self.BaseUrl];
    
    
}


@end
