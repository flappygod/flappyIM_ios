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

//基础地址
@property(nonatomic,copy) NSString* BaseUrl;
//基础地址
@property(nonatomic,copy) NSString* BaseUploadUrl;


@property(nonatomic,copy) NSString* URL_uploadUrl;
@property(nonatomic,copy) NSString* URL_register;
@property(nonatomic,copy) NSString* URL_login;
@property(nonatomic,copy) NSString* URL_logout;
@property(nonatomic,copy) NSString* URL_autoLogin;
@property(nonatomic,copy) NSString* URL_createSingleSession;
@property(nonatomic,copy) NSString* URL_getSingleSession;
@property(nonatomic,copy) NSString* URL_createGroupSession;
@property(nonatomic,copy) NSString* URL_getSessionByID;
@property(nonatomic,copy) NSString* URL_getUserSessions;
@property(nonatomic,copy) NSString* URL_addUserToSession;
@property(nonatomic,copy) NSString* URL_delUserInSession;


//重新设置服务器地址
-(void)resetServer:(NSString*)serverUrl
      andUploadUrl:(NSString*)upload;


@end

NS_ASSUME_NONNULL_END
