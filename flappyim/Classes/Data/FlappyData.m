//
//  FlappyData.m
//  flappyim
//
//  Created by lijunlin on 2019/8/8.
//

#import "FlappyData.h"
#import "FlappyJsonTool.h"
#import "FlappyDef.h"
#import "MJExtension.h"


#define  KEY_USER  @"KEY_USER"

#define  KEY_USER_TOKEN  @"KEY_USER_TOKEN"

#define  KEY_DEVICE_PLAT  @"KEY_DEVICE_PLAT"

#define  KEY_PUSH_TYPE  @"KEY_PUSH_TYPE"

#define  KEY_PUSH_PLAT  @"KEY_PUSH_PLAT"

#define  KEY_PUSHID  @"KEY_PUSHID"

#define  KEY_DEVICE_ID  @"KEY_DEVICE_ID"

#define  KEY_RSA_PUBLIC_KEY  @"KEY_RSA_PUBLIC_KEY"

#define  KEY_PUSHSETTING  @"KEY_PUSHSETTING"




#define DEFAULT_DEVICE_PLAT @"IOS"

#define DEFAULT_PUSH_PLAT   @"APNS"


//数据缓存
@implementation FlappyData{
    ChatUser* _cachedUser;
}


//使用单例模式
+ (instancetype)shareInstance {
    static FlappyData *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        _sharedSingleton = [[super allocWithZone:NULL] init];
    });
    return _sharedSingleton;
}

//保存用户
-(void)saveUser:(ChatUser*)user{
    _cachedUser=user;
    NSString*  str=[FlappyJsonTool JSONObjectToJSONString:[user mj_keyValues]];
    UNSaveObject(str, KEY_USER);
}

//获取用户
-(ChatUser*)getUser{
    if(_cachedUser!=nil){
        return  _cachedUser;
    }
    NSString* str=UNGetObject(KEY_USER);
    if(str!=nil){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:str];
        _cachedUser=[ChatUser mj_objectWithKeyValues:dic];
        return _cachedUser;
    }
    return nil;
}

//清空用户
-(void)clearUser{
    _cachedUser=nil;
    UNSaveObject(@"", KEY_USER);
}


//设置设备平台
-(void)saveDevicePlat:(NSString*)devicePlat{
    UNSaveObject(devicePlat, KEY_DEVICE_PLAT);
}

//获取设备平台
-(NSString*)getDevicePlat{
    NSString* devicePlat = UNGetObject(KEY_DEVICE_PLAT);
    return  (devicePlat==nil) ? DEFAULT_DEVICE_PLAT : devicePlat;
}

//保存推送类型
-(void)savePushType:(NSString*)pushType{
    UNSaveObject(pushType, KEY_PUSH_TYPE);
}

//获取推送类型
-(NSString*)getPushType{
    NSString* pushType = UNGetObject(KEY_PUSH_TYPE);
    return  (pushType==nil) ? @"0" : pushType;
}

//保存推送类型
-(void)savePushPlat:(NSString*)pushPlat{
    UNSaveObject(pushPlat, KEY_PUSH_PLAT);
}

//获取推送类型
-(NSString*)getPushPlat{
    NSString* pushPlat = UNGetObject(KEY_PUSH_PLAT);
    return  (pushPlat==nil) ? DEFAULT_PUSH_PLAT : pushPlat;
}

//保存
-(void)savePushId:(NSString*)pushID{
    UNSaveObject(pushID, KEY_PUSHID);
}

//获取推送ID
-(NSString*)getPushId{
    NSString* pushId = UNGetObject(KEY_PUSHID);
    return  (pushId==nil) ? @"":pushId;
}

//获取推送ID
-(NSString*)getDeviceId{
    NSString* deviceId = UNGetObject(KEY_DEVICE_ID);
    if(deviceId==nil){
        deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        UNSaveObject(deviceId, KEY_DEVICE_ID);
    }
    return deviceId;
}


//保存推送设置
-(void)savePushSetting:(PushSettings*)setting{
    //更新推送信息，并保存起来
    PushSettings* update = [self getPushSetting];
    update = (update==nil ? [[PushSettings alloc] init]:update);
    update.routePushPrivacy = (setting.routePushPrivacy == nil ? update.routePushPrivacy:setting.routePushPrivacy);
    update.routePushLanguage = (setting.routePushLanguage == nil ? update.routePushLanguage:setting.routePushLanguage);
    update.routePushMute = (setting.routePushMute == nil ? update.routePushMute:setting.routePushMute);
    update.routePushType = (setting.routePushType == nil ? update.routePushType:setting.routePushType);
    update.routePushPlat = (setting.routePushPlat == nil ? update.routePushPlat:setting.routePushPlat);
    update.routePushId = (setting.routePushId == nil ? update.routePushId:setting.routePushId);
    NSString*  str=[FlappyJsonTool JSONObjectToJSONString:[update mj_keyValues]];
    UNSaveObject(str, KEY_PUSHSETTING);
}

//获取推送设置
-(PushSettings*)getPushSetting{
    NSString* str=UNGetObject(KEY_PUSHSETTING);
    if(str!=nil){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:str];
        PushSettings* ret=[PushSettings mj_objectWithKeyValues:dic];
        return ret;
    }
    return nil;
}

//RSA秘钥
-(void)saveRsaPublicKey:(NSString*)key{
    UNSaveObject(key, KEY_RSA_PUBLIC_KEY);
}

//获取RSA秘钥
-(NSString*)getRsaPublicKey{
    return UNGetObject(KEY_RSA_PUBLIC_KEY);
}

//保存鉴权
-(void)saveAuthToken:(NSString*)token{
    UNSaveObject(token, KEY_USER_TOKEN);
}

//获取鉴权
-(NSString*)getAuthToken{
    return UNGetObject(KEY_USER_TOKEN);
}

@end
