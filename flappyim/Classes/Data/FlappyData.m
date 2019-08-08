//
//  FlappyData.m
//  flappyim
//
//  Created by lijunlin on 2019/8/8.
//

#import "FlappyData.h"
#import "JsonTool.h"
#import "CommonDef.h"
#import "MJExtension.h"


#define  KEY_USER  @"KEY_USER"

@implementation FlappyData



//保存用户
+(void)saveUser:(User*)user{
    //装环为字符串
    NSString*  str=[JsonTool JSONObjectToJSONString:[user mj_keyValues]];
    UNSaveObject(str, KEY_USER);
}

//获取用户
+(User*)getUser{
    NSString* str=UNGetObject(KEY_USER);
    if(str!=nil){
        NSDictionary* dic=[JsonTool JSONStringToDictionary:str];
        User* ret=[User mj_objectWithKeyValues:dic];
        return ret;
    }
    return nil;
}

//清空用户
+(void)clearUser{
    UNSaveObject(@"", KEY_USER);
}

@end
