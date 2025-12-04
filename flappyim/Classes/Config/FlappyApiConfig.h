//
//  FlappyApiConfig.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlappyApiConfig : NSObject


+ (instancetype)shareInstance;

//心跳间隔
@property (nonatomic,assign) NSInteger  heartInterval;
//自动登录间隔
@property (nonatomic,assign) NSInteger  autoLoginInterval;


//基础地址
@property(nonatomic,copy) NSString* BaseUrl;
//基础地址
@property(nonatomic,copy) NSString* BaseUploadUrl;
//上传文件的地址
@property(nonatomic,copy) NSString* URL_fileUpload;
//视频上传
@property(nonatomic,copy) NSString* URL_videoUpload;
//修改推送
@property(nonatomic,copy) NSString* URL_changePush;
//注册
@property(nonatomic,copy) NSString* URL_register;
//更新用户信息
@property(nonatomic,copy) NSString* URL_update;
//登录
@property(nonatomic,copy) NSString* URL_login;
//登出
@property(nonatomic,copy) NSString* URL_logout;
//自动登录
@property(nonatomic,copy) NSString* URL_autoLogin;
//创建单聊
@property(nonatomic,copy) NSString* URL_createSingleSession;
//获取单聊
@property(nonatomic,copy) NSString* URL_getSingleSession;
//创建群聊
@property(nonatomic,copy) NSString* URL_createGroupSession;
//更新会话信息
@property(nonatomic,copy) NSString* URL_updateSessionData;
//获取会话
@property(nonatomic,copy) NSString* URL_getSessionByExtendId;
//获取会话
@property(nonatomic,copy) NSString* URL_getSessionById;
//获取所有会话
@property(nonatomic,copy) NSString* URL_getUserSessionList;
//添加用户到会话
@property(nonatomic,copy) NSString* URL_addUserToSession;
//添加用户到会话
@property(nonatomic,copy) NSString* URL_addUsersToSession;
//删除会话中的用户
@property(nonatomic,copy) NSString* URL_delUserInSession;
//启用/禁用会话
@property(nonatomic,copy) NSString* URL_setSessionEnable;
//删除会话
@property(nonatomic,copy) NSString* URL_deleteSession;



//重新设置服务器地址
-(void)resetServer:(NSString*)serverUrl
      andUploadUrl:(NSString*)upload;


@end

NS_ASSUME_NONNULL_END
