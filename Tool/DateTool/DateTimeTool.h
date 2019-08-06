//
//  DateTimeTool.h
//  driver
//
//  Created by macbook air on 16/7/22.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateTimeTool : NSObject


//格式化字符串，替换不正常
+(NSString*)formatNorMalTimeStr:(NSString*)time;

//将字符串转换为时间
+(NSDate*)formatNorMalTime:(NSString*)time;

//将时间转换为字符串
+(NSString*)formatNorMalTimeStrFromDate:(NSDate*)date;

//通过时间戳转化时间
+(NSDate*)dateFromLongLong:(long long)msSince1970;

//时间转换时间戳
+(long long)longLongFromDate:(NSDate*)date;

//获取这个时间和当前时间的对比字符串显示
+(NSString*)getDateStringCompareNower:(NSDate*) date;

//只保留日期
+(NSString*)formatOnlyDataStr:(NSString*)time;

//只保留日期
+(NSString*)formatOnlyData:(NSDate*)date;



@end
