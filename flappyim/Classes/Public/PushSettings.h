//
//  PushSettings.h
//  flappyim
//
//  Created by li lin on 2024/4/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PushSettings : NSObject

//推送类型
@property(nonatomic,copy) NSString*  routePushType;

//推送语言
@property(nonatomic,copy) NSString* routePushLanguage;

//推送隐私
@property(nonatomic,copy) NSString* routePushPrivacy;

//推送免打扰
@property(nonatomic,copy) NSString* routePushMute;

@end

NS_ASSUME_NONNULL_END
