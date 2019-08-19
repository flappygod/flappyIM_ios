//
//  DateTimeTool.m
//  driver
//
//  Created by macbook air on 16/7/22.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import "FlappyDateTool.h"

@implementation FlappyDateTool


//获取这个时间和当前时间的对比字符串显示
+(NSString*)getDateStringCompareNower:(NSDate*) date{
    //计算出时间显示
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //默认格式
    dateFormatter.dateFormat = @"MM月dd日 HH:mm";
    NSString* time=[dateFormatter stringFromDate:date];
    
    NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSDate *today = [[NSDate alloc] init];
    NSDate *tomorrow, *yesterday;
    
    tomorrow = [today dateByAddingTimeInterval: secondsPerDay];
    yesterday = [today dateByAddingTimeInterval: -secondsPerDay];
    
    // 10 first characters of description is the calendar date:
    NSString * todayString = [[today description] substringToIndex:10];
    NSString * yesterdayString = [[yesterday description] substringToIndex:10];
    
    NSString * dateString = [[date description] substringToIndex:10];
    
    if ([dateString isEqualToString:todayString])
    {
        dateFormatter.dateFormat = @"HH:mm";
        time=[dateFormatter stringFromDate:date];
    } else if ([dateString isEqualToString:yesterdayString])
    {
        dateFormatter.dateFormat = @"昨天 HH:mm";
        time=[dateFormatter stringFromDate:date];
    }
    return time;
}


//格式化时间
+(NSString*)formatNorMalTimeStrFromDate:(NSDate*)date{
    //时间
    if(date!=nil){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        NSString *now = [dateFormatter stringFromDate:date];
        return now;
    }else{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        NSString *now = [dateFormatter stringFromDate:[NSDate date]];
        return now;
    }
}




//时间戳转换时间
+(NSDate*)dateFromLongLong:(long long)msSince1970{
    return [NSDate dateWithTimeIntervalSince1970:msSince1970 / 1000];
}

//时间转换时间戳
+(long long)longLongFromDate:(NSDate*)date{
    return [date timeIntervalSince1970] * 1000;
}


+(NSString*)formatOnlyDataStr:(NSString*)time{
    if(time!=nil){
        //时间字符串
        NSString *timeStr=time;
        NSRange range = [timeStr rangeOfString:@"."];
        //去掉小数点后面的
        if(range.location !=NSNotFound)
        {
            timeStr= [timeStr componentsSeparatedByString:@"."][0];
        }
        //时间
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        //去掉Z
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"Z" withString:@" "];
        //替换
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        //两边空格
        timeStr=[timeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        
        NSDateFormatter *dateFormatterOne = [[NSDateFormatter alloc] init];
        [dateFormatterOne setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
        [dateFormatterOne setLocale:[NSLocale currentLocale]];
        NSDate *date = [dateFormatterOne dateFromString:timeStr];
        
        
        NSDateFormatter *dateFormatterTwo = [[NSDateFormatter alloc] init];
        [dateFormatterTwo setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd"]];
        [dateFormatterTwo setLocale:[NSLocale currentLocale]];
        
        
        NSString *now = [dateFormatterTwo stringFromDate:date];
        return now;
    }else{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd"]];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        NSString *now = [dateFormatter stringFromDate:[NSDate date]];
        return now;
    }
}


+(NSString*)formatOnlyData:(NSDate*)date{
    //时间
    if(date!=nil){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd"]];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        NSString *now = [dateFormatter stringFromDate:date];
        return now;
    }else{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd"]];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        NSString *now = [dateFormatter stringFromDate:[NSDate date]];
        return now;
    }
}




//格式化时间
+(NSString*)formatNorMalTimeStr:(NSString*)time{
    if(time!=nil){
        //时间字符串
        NSString *timeStr=time;
        NSRange range = [timeStr rangeOfString:@"."];
        //去掉小数点后面的
        if(range.location !=NSNotFound)
        {
            timeStr= [timeStr componentsSeparatedByString:@"."][0];
        }
        //时间
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        //去掉Z
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"Z" withString:@" "];
        //替换
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        //两边空格
        timeStr=[timeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        
        NSDate *date = [dateFormatter dateFromString:timeStr];
        NSString *now = [dateFormatter stringFromDate:date];
        return now;
    }else{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        NSString *now = [dateFormatter stringFromDate:[NSDate date]];
        return now;
    }
}

//时间
+(NSDate*)formatNorMalTime:(NSString*)time{
    if(time!=nil)
    {
        //时间字符串
        NSString *timeStr=time;
        //range
        NSRange range = [timeStr rangeOfString:@"."];
        //location
        if(range.location !=NSNotFound)
        {
            timeStr= [timeStr componentsSeparatedByString:@"."][0];
        }
        //替换时间字符串
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        //去掉Z
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"Z" withString:@" "];
        //替换时间字符串
        timeStr= [timeStr stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        //两边空格
        timeStr=[timeStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        //格式化
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        NSDate *date = [dateFormatter dateFromString:timeStr];
        //时间
        return date;
    }else{
        return [NSDate date];
    }
}



@end
