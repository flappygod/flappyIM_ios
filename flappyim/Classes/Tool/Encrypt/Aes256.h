//
//  Aes256.h
//  flutterflappyaes
//
//  Created by lijunlin on 2/19/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Aes256 : NSObject



+(NSString *)AesCBC256Encrypt:(NSString *)text
                   withKey:(NSString *)key
                    withIv:(NSString *)iv;

+(NSString *)AesCBC256Decrypt:(NSString *)text
                   withKey:(NSString *)key
                    withIv:(NSString *)iv;

+(NSString *)AES256Encrypt:(NSString *)text
                   withKey:(NSString *)key;


+(NSString *)AES256Decrypt:(NSString *)text
                   withKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
