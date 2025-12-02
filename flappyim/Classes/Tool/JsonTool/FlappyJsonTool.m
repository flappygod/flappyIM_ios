//
//  JSONremoveNil.m
//  EtongIOSApp
//
//  Created by admin on 15-1-8.
//  Copyright (c) 2015年 etong. All rights reserved.
//

#import "FlappyJsonTool.h"

@implementation FlappyJsonTool



+(NSString*)jsonObjectToJsonStr:(id)dictonary{
    //如果可以转为JSon
    if ([NSJSONSerialization isValidJSONObject:dictonary]){
        //创造一个json从Data, NSJSONWritingPrettyPrinted指定的JSON数据产的空白，使输出更具可读性。
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictonary options:0 error:&error];
        NSString *json =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [json stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    }
    //返回一个空的
    return nil;
}


+(id)jsonStrToObject:(NSString *)json {
    if (!json || ![json isKindOfClass:[NSString class]]) {
        NSLog(@"Invalid input: JSON string is nil or not a string.");
        return nil;
    }
    id response = nil;
    @try {
        //将字符串转换为NSData
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSError *error = nil;
            response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (error) {
                NSLog(@"JSON parsing error: %@", error.localizedDescription);
            }
        } else {
            NSLog(@"Failed to convert JSON string to NSData.");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception occurred while parsing JSON: %@", exception.description);
    }
    return response;
}



@end
