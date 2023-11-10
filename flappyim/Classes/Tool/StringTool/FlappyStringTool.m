//
//  StringTool.m
//  driver
//
//  Created by macbook air on 16/10/8.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import "FlappyStringTool.h"

@implementation FlappyStringTool


+ (NSString *)uuidString
{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];
    CFRelease(uuid_ref);
    CFRelease(uuid_string_ref);
    return [[uuid lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

+ (BOOL)checkEmail:(NSString *)email{
    
    //^(\\w)+(\\.\\w+)*@(\\w)+((\\.\\w{2,3}){1,3})$
    
    NSString *regex = @"^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\\.[a-zA-Z0-9_-]+)+$";
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    return [emailTest evaluateWithObject:email];
    
}
//判断字符串是不是空的
+(Boolean)isStringEmpty:(NSString* )str {
    if(str==nil||[str isEqual:[NSNull null]]||[str isEqual:@""]||[str isEqual:@" "]){
        return true;
    }
    return false;
}

//判断字符串是不是空的或者为零
+(Boolean)isStringEmptyOrZero:(NSString* )str {
    if(str==nil||[str isEqual:[NSNull null]]||[str isEqual:@""]||[str isEqual:@"0"]){
        return true;
    }
    return false;
}

//转换成不为空的字符串
+(NSString*)toUnNullStr:(NSString*) str{
    //如果是空的
    if(str==nil)
    {
        return @"";
    }
    //如果是空的
    if([str isEqual:[NSNull null]])
    {
        return @"";
    }
    if([str isEqual:@"null"])
    {
        return @"";
    }
    //直接返回这个字符串
    return [NSString stringWithFormat:@"%@",str];
}

//转换成不为空的字符串
+(NSString*)toUnNullStr:(NSString*) str
     withPlaceHolderStr:(NSString*) palce{
    //如果是空的
    if(str==nil)
    {
        return palce;
    }
    //如果是空的
    if([str isEqual:[NSNull null]])
    {
        return palce;
    }
    //如果是空的
    if([str isEqual:@""])
    {
        return palce;
    }
    //直接返回这个字符串
    return [NSString stringWithFormat:@"%@",str];
}

//将空的字符串都转换为0
+(NSString*)toUnNullZeroStr:(NSString*) str{
    //如果是空的
    if(str==nil)
    {
        return @"0";
    }
    //如果是空的
    if([str isEqual:[NSNull null]])
    {
        return @"0";
    }
    //如果是空的
    if([str isEqual:@""]||[str isEqual:@" "]||[str isEqual:@"<null>"]||[str isEqual:@"null"])
    {
        return @"0";
    }
    //直接返回这个字符串
    return [NSString stringWithFormat:@"%@",str];;
}


//随机数
+(NSString *)RandomString:(NSInteger) length
{
    char data[length];
    for (int x=0;x<length;data[x++] = (char)('A' + (arc4random_uniform(26))));
    return [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
    
}



//过滤html
+(NSString *)filterHTML:(NSString *)html
{
    NSScanner * scanner = [NSScanner scannerWithString:html];
    NSString * text = nil;
    while([scanner isAtEnd]==NO)
    {
        [scanner scanUpToString:@"<" intoString:nil];
        [scanner scanUpToString:@">" intoString:&text];
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>",text] withString:@""];
    }
    return html;
}

//过滤
+(NSString*)filterSpace:(NSString *)html{
    NSString* string=[html stringByReplacingOccurrencesOfString:@"\t"withString:@""];
    string=[string stringByReplacingOccurrencesOfString:@"\r"withString:@""];
    string=[string stringByReplacingOccurrencesOfString:@"\n"withString:@""];
    string=[string stringByReplacingOccurrencesOfString:@"&nbsp;"withString:@""];
    return string;
}

//获取图片列表
+(NSArray *)filterImage:(NSString *)html
{
    NSMutableArray *resultArray = [NSMutableArray array];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<(img|IMG)(.*?)(/>|></img>|>)" options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    NSArray *result = [regex matchesInString:html options:NSMatchingReportCompletion range:NSMakeRange(0, html.length)];
    
    for (NSTextCheckingResult *item in result) {
        NSString *imgHtml = [html substringWithRange:[item rangeAtIndex:0]];
        
        NSArray *tmpArray = nil;
        if ([imgHtml rangeOfString:@"src=\""].location != NSNotFound) {
            tmpArray = [imgHtml componentsSeparatedByString:@"src=\""];
        } else if ([imgHtml rangeOfString:@"src="].location != NSNotFound) {
            tmpArray = [imgHtml componentsSeparatedByString:@"src="];
        }
        
        if (tmpArray.count >= 2) {
            NSString *src = tmpArray[1];
            
            NSUInteger loc = [src rangeOfString:@"\""].location;
            if (loc != NSNotFound) {
                src = [src substringToIndex:loc];
                [resultArray addObject:src];
            }
        }
    }
    
    return resultArray;
}

//url解码
+(NSString *)URLDecodedString:(NSString *)str
{
    
    NSString *decodedString = (NSString*)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, CFSTR("")));
    decodedString=[decodedString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return decodedString;
}







@end
