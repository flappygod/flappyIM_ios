//
//  StringTool.h
//  driver
//
//  Created by macbook air on 16/10/8.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlappyStringTool : NSObject

//生成一个UUID
+ (NSString *)uuidString;

//判断字符串是不是空的
+(Boolean)isStringEmpty:(NSString* )str;

//判断字符串是不是空的或者为零
+(Boolean)isStringEmptyOrZero:(NSString* )str;

//转换成不为空的字符串
+(NSString*)toUnNullStr:(NSString*) str;

//转换成不为空的字符串
+(NSString*)toUnNullStr:(NSString*) str
     withPlaceHolderStr:(NSString*) palce;

//将空的字符串都转换为0
+(NSString*)toUnNullZeroStr:(NSString*) str;

//生成指定长度的字符串
+(NSString *)RandomString:(NSInteger) length;

//检查是否是email
+ (BOOL)checkEmail:(NSString *)email;

//过滤html标签
+(NSString *)filterHTML:(NSString *)html;

//过滤空格换行
+(NSString*)filterSpace:(NSString *)html;

//获取图片的列表
+(NSArray *)filterImage:(NSString *)html;

//url解码
+(NSString *)URLDecodedString:(NSString *)str;


@end
