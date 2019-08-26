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
#define  KEY_PUSHTYPE  @"KEY_PUSHTYPE"

@implementation FlappyData
{
    ChatUser* _user;
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
    _user=user;
    //装环为字符串
    NSString*  str=[FlappyJsonTool JSONObjectToJSONString:[user mj_keyValues]];
    UNSaveObject(str, KEY_USER);
}
    
//获取用户
-(ChatUser*)getUser{
    if(_user!=nil){
        return _user;
    }
    NSString* str=UNGetObject(KEY_USER);
    if(str!=nil){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:str];
        ChatUser* ret=[ChatUser mj_objectWithKeyValues:dic];
        _user=ret;
        return ret;
    }
    return nil;
}
    
//保存
-(void)savePush:(NSString*)pushID{
    UNSaveObject(pushID, KEY_PUSHID);
}
    
//获取推送ID
-(NSString*)getPush{
    NSString* str=UNGetObject(KEY_PUSHID);
    return str;
}
    

-(void)savePushType:(NSString*)type{
    UNSaveObject(type, KEY_PUSHTYPE);
}
    
-(NSString*)getPushType{
    NSString* str=UNGetObject(KEY_PUSHTYPE);
    return str;
}

//清空用户
-(void)clearUser{
    UNSaveObject(@"", KEY_USER);
}
    
    @end
