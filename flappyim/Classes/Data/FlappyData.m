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
#define  KEY_PUSHID  @"KEY_PUSHID"
#define  KEY_DEVICE_ID  @"KEY_DEVICE_ID"
#define  KEY_RSA_KEY  @"KEY_RSA_KEY"
#define  KEY_PUSHSETTING  @"KEY_PUSHSETTING"



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
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:str];
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
    NSString*  str=[FlappyJsonTool JSONObjectToJSONString:[update mj_keyValues]];
    UNSaveObject(str, KEY_PUSHSETTING);
}

//获取推送设置
-(PushSettings*)getPushSetting{
    NSString* str=UNGetObject(KEY_PUSHSETTING);
    if(str!=nil){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:str];
        PushSettings* ret=[PushSettings mj_objectWithKeyValues:dic];
        return ret;
    }
    return nil;
}

//RSA秘钥
-(void)saveRsaKey:(NSString*)key{
    UNSaveObject(key, KEY_RSA_KEY);
}

//获取RSA秘钥
-(NSString*)getRsaKey{
    return UNGetObject(KEY_RSA_KEY);
}

@end
