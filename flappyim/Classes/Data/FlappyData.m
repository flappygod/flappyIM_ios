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

@implementation FlappyData



//保存用户
+(void)saveUser:(ChatUser*)user{
    //装环为字符串
    NSString*  str=[FlappyJsonTool JSONObjectToJSONString:[user mj_keyValues]];
    UNSaveObject(str, KEY_USER);
}

//获取用户
+(ChatUser*)getUser{
    NSString* str=UNGetObject(KEY_USER);
    if(str!=nil){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:str];
        ChatUser* ret=[ChatUser mj_objectWithKeyValues:dic];
        return ret;
    }
    return nil;
}

//保存
+(void)savePush:(NSString*)pushID{
    UNSaveObject(pushID, KEY_PUSHID);
}

//获取推送ID
+(NSString*)getPush{
    NSString* str=UNGetObject(KEY_PUSHID);
    return str;
}


//清空用户
+(void)clearUser{
    UNSaveObject(@"", KEY_USER);
}

@end
