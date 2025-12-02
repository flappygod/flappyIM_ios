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
对象转换为jsonstring
 *************************/
+(NSString*)jsonObjectToJsonStr:(id)dictonary;

/*************************
 jsonstring转换为对象
 *************************/
+(id)jsonStrToObject:(NSString*)json;


@end
