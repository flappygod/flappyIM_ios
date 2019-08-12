//
//  ChatVoice.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatVoice : NSObject


//发送的本地地址
@property(nonatomic,copy) NSString*  sendPath;

//网络语音的地址
@property(nonatomic,copy) NSString* path;

//当前语音的秒数
@property(nonatomic,copy) NSString* seconds;


@end

NS_ASSUME_NONNULL_END
