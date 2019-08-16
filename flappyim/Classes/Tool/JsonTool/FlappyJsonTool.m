//
//  JSONremoveNil.m
//  EtongIOSApp
//
//  Created by admin on 15-1-8.
//  Copyright (c) 2015年 etong. All rights reserved.
//

#import "FlappyJsonTool.h"

@implementation FlappyJsonTool



+(NSString*)DicToJSONString:(id)dictonary{
    //如果可以转为JSon
    if ([NSJSONSerialization isValidJSONObject:dictonary]){
        NSError *error;
        // 创造一个json从Data, NSJSONWritingPrettyPrinted指定的JSON数据产的空白，使输出更具可读性。
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictonary options:0 error:&error];
        NSString *json =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [json stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    }
    //返回一个空的
    return nil;
}


+(NSString*)DicToJSONStringHasBlank:(id)dictonary{
    //如果可以转为JSon
    if ([NSJSONSerialization isValidJSONObject:dictonary]){
        NSError *error;
        // 创造一个json从Data, NSJSONWritingPrettyPrinted指定的JSON数据产的空白，使输出更具可读性。
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictonary options:0 error:&error];
        NSString *json =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [json stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    }
    //返回一个空的
    return nil;
}

+(NSString*)JSONObjectToJSONString:(id)json{
    //如果可以转为JSon
    if ([NSJSONSerialization isValidJSONObject:json]){
        NSError *error;
        // 创造一个json从Data, NSJSONWritingPrettyPrinted指定的JSON数据产的空白，使输出更具可读性。
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
        NSString *json =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        return [json stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
    }
    //返回一个空的
    return nil;
}

+(NSDictionary*)JSONStringToDictionary:(NSString*)json{
    NSDictionary *respStr;
    @try {
        //如果可以转为JSon
        NSData* data = [json dataUsingEncoding:NSUTF8StringEncoding];
        if (data!=nil) {
            NSError *error=nil;
            respStr =[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            //返回一个空的
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception.description);
    }
    @finally {
        
    }
    
    return respStr;
}



@end
