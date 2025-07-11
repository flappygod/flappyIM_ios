//
//  FlappyBaseSession.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import <Foundation/Foundation.h>
#import "FlappyIM.h"
#import "FlappyApiRequest.h"
#import "ChatImage.h"
#import "ChatVoice.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyBaseSession : NSObject


//转换为
+(Message*)changeToMessage:(ChatMessage*)chatmsg
          andChannelSecret:(NSString*) channelSecret;


@end

NS_ASSUME_NONNULL_END
