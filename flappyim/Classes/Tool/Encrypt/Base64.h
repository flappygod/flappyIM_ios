//
//  CommonFunc.h
//  PRJ_base64
//
//  Created by wangzhipeng on 12-11-29.
//  Copyright (c) 2012年 com.comsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#define __BASE64( text )        [CommonFunc base64StringFromText:text]
#define __TEXT( base64 )        [CommonFunc textFromBase64String:base64]

@interface Base64 : NSObject


+ (NSString *)base64StringFromText:(NSString *)text;

+ (NSString *)textFromBase64String:(NSString *)base64;

+ (NSString *)base64EncodedStringFrom:(NSData *)data;

+ (NSData *)dataWithBase64EncodedString:(NSString *)string;

@end
