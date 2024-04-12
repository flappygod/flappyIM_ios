//
//  RSATool.h
//  AFNetworking
//
//  Created by li lin on 2024/4/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RSATool : NSObject

///通过公钥加密
+(NSString*)encryptWithPublicKey:(NSString*)publicKey
                        withData:(NSString*)data;


///通过私钥加密
+(NSString*)decryptWithPrivateKeyPKCS1:(NSString*)privateKey
                         withData:(NSString*)data;




@end

NS_ASSUME_NONNULL_END
