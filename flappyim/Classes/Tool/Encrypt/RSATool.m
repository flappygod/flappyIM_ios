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
    // 将PEM格式的公钥和私钥转换为NSData
    NSData *publicKeyData = [publicKey dataUsingEncoding:NSUTF8StringEncoding];
    
    // 加载公钥
    SecKeyRef publicKeyRef = SecKeyCreateWithData((__bridge CFDataRef)publicKeyData, (__bridge CFDictionaryRef)@{}, NULL);
    
    // 要加密的数据
    NSData *dataToEncrypt = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    // 使用公钥加密
    CFErrorRef error = NULL;
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
+(NSString*)decryptWithPrivateKey:(NSString*)privateKey
                         withData:(NSString*)data{
    
    //将PEM格式的公钥和私钥转换为NSData
    NSData *privateKeyData = [privateKey dataUsingEncoding:NSUTF8StringEncoding];
    
    //加载私钥
    SecKeyRef privateKeyRef = SecKeyCreateWithData((__bridge CFDataRef)privateKeyData, (__bridge CFDictionaryRef)@{}, NULL);
    
    //要加密的数据
    NSString *originalString = @"这是一个需要加密的消息!";
    NSData *dataToEncrypt = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    
    //使用公钥加密
    CFErrorRef error = NULL;
    
    //Base64解密
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:data options:0];
    
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


@end
