//
//  AES128CBC_No_Padding_Unit.h
//
//
//  Created by apple on 14-5-13.
//  Copyright (c) 2014年 akforsure. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Aes128: NSObject


+(NSString *)AesCBC128Encrypt:(NSString *)text
                   withKey:(NSString *)key
                    withIv:(NSString *)iv;



+(NSString *)AesCBC128Decrypt:(NSString *)text
                   withKey:(NSString *)key
                    withIv:(NSString *)iv;


//AES128 ecb Encrypt
+(NSString *)AES128Encrypt:(NSString *)text
                   withKey:(NSString *)key;

//AES128 ecb Decrypt
+(NSString *)AES128Decrypt:(NSString *)text
                   withKey:(NSString *)key;



@end
