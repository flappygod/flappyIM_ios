//
//  JSONremoveNil.h
//  EtongIOSApp
//
//  Created by admin on 15-1-8.
//  Copyright (c) 2015年 etong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlappyJsonTool : NSObject


/*************************
 字典转换为jsonstring
 *************************/
+(NSString*)DicToJSONString:(id)dictonary;
+(NSString*)DicToJSONStringHasBlank:(id)dictonary;
/*************************
 json转换为jsonstring
 *************************/
+(NSString*)JSONObjectToJSONString:(id)json;
/*************************
 jsonstring转换为数据字典
 *************************/
+(NSDictionary*)JSONStringToDictionary:(NSString*)json;


@end
