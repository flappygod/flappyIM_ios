//
//  ChatVoice.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatVoice : NSObject


//地址
@property(nonatomic,copy) NSString* path;

//声音有多少秒
@property(nonatomic,assign) NSInteger seconds;


@end

NS_ASSUME_NONNULL_END
