//
//  RSATool.m
//  AFNetworking
//
//  Created by li lin on 2024/4/12.
//

#import "RSATool.h"

@implementation RSATool

///通过公钥加密
+(NSString*)encryptWithPublicKey:(NSString*)publicKey
                        withData:(NSString*)data{
    //转换Data
    SecKeyRef publicKeyRef = [self publicKeyRefFromPem:publicKey];
    // 要加密的数据
    NSData *dataToEncrypt = [data dataUsingEncoding:NSUTF8StringEncoding];
    //错误
    CFErrorRef error = NULL;
    // 使用公钥加密
    NSData *encryptedData = (NSData *)CFBridgingRelease(SecKeyCreateEncryptedData(publicKeyRef, kSecKeyAlgorithmRSAEncryptionPKCS1, (__bridge CFDataRef)dataToEncrypt, &error));
    // 释放密钥引用
    if (publicKeyRef) CFRelease(publicKeyRef);
    //加密
    if (!error) {
        // 加密成功
        return [encryptedData base64EncodedStringWithOptions:0];;
    } else {
        // 加密失败
        NSError *err = CFBridgingRelease(error);
        NSLog(@"加密失败: %@", err);
        return nil;
    }
}

///通过私钥加密
+(NSString*)decryptWithPrivateKeyPKCS1:(NSString*)privateKey
                              withData:(NSString*)data{
    //加载私钥
    SecKeyRef privateKeyRef = [self privateRefFromPemPKCS1:privateKey];
    //Base64解密
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:data options:0];
    //错误
    CFErrorRef error = NULL;
    //使用私钥解密
    NSData *decryptedData = (NSData *)CFBridgingRelease(SecKeyCreateDecryptedData(privateKeyRef, kSecKeyAlgorithmRSAEncryptionPKCS1, (__bridge CFDataRef)encryptedData, &error));
    //解密数据释放
    if (privateKeyRef) CFRelease(privateKeyRef);
    //结果判断
    if (!error) {
        // 解密成功
        return  [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    } else {
        // 解密失败
        NSError *err = CFBridgingRelease(error);
        NSLog(@"解密失败: %@", err);
        return nil;
    }
}

//加载公钥
+ (SecKeyRef)publicKeyRefFromPem:(NSString*)publicKeyString{
    // 移除PEM字符串的头部和尾部
    NSString *header = @"-----BEGIN PUBLIC KEY-----";
    NSString *footer = @"-----END PUBLIC KEY-----";
    NSString *pemStripped = [publicKeyString stringByReplacingOccurrencesOfString:header withString:@""];
    pemStripped = [pemStripped stringByReplacingOccurrencesOfString:footer withString:@""];
    pemStripped = [pemStripped stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    pemStripped = [pemStripped stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    pemStripped = [pemStripped stringByReplacingOccurrencesOfString:@" " withString:@""];
    // Base64解码
    NSData *publicKeyData = [[NSData alloc] initWithBase64EncodedString:pemStripped
                                                                options:0];
    if (!publicKeyData) {
        NSLog(@"Error decoding public key.");
        return nil;
    }
    // 创建密钥字典以添加到密钥链
    NSDictionary *options = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic,
        (__bridge id)kSecAttrKeySizeInBits: @(2048),
        (__bridge id)kSecPublicKeyAttrs: @{
            (__bridge id)kSecAttrIsPermanent: @NO
        }
    };
    CFErrorRef error = NULL;
    SecKeyRef publicKeyRef = SecKeyCreateWithData((__bridge CFDataRef)publicKeyData, (__bridge CFDictionaryRef)options, &error);
    if (!publicKeyRef) {
        NSError *err = CFBridgingRelease(error); // ARC takes ownership
        NSLog(@"Error creating public key: %@", err);
        return nil;
    }
    return publicKeyRef;
}

//加载公钥
+ (SecKeyRef)privateRefFromPemPKCS1:(NSString*)privatekeyString{
    // 移除PEM字符串的头部和尾部
    NSString *header = @"-----BEGIN RSA PRIVATE KEY-----";
    NSString *footer = @"-----END RSA PRIVATE KEY-----";
    NSString *pemStripped = [privatekeyString stringByReplacingOccurrencesOfString:header withString:@""];
    pemStripped = [pemStripped stringByReplacingOccurrencesOfString:footer withString:@""];
    pemStripped = [pemStripped stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    pemStripped = [pemStripped stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    pemStripped = [pemStripped stringByReplacingOccurrencesOfString:@" " withString:@""];
    // Base64解码
    NSData *privateKeyData = [[NSData alloc] initWithBase64EncodedString:pemStripped
                                                                 options:0];
    if (!privateKeyData) {
        NSLog(@"Error decoding private key.");
        return nil;
    }
    // 创建密钥字典以添加到密钥链
    NSDictionary *options = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPrivate,
        (__bridge id)kSecAttrKeySizeInBits: @(2048),
        (__bridge id)kSecPrivateKeyAttrs: @{
            (__bridge id)kSecAttrIsPermanent: @NO
        }
    };
    CFErrorRef error = NULL;
    SecKeyRef privateKeyRef = SecKeyCreateWithData((__bridge CFDataRef)privateKeyData, (__bridge CFDictionaryRef)options, &error);
    if (!privateKeyRef) {
        NSError *err = CFBridgingRelease(error); // ARC takes ownership
        NSLog(@"Error creating private key: %@", err);
        return nil;
    }
    return privateKeyRef;
}



@end
