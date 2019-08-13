//
//  FlappyBaseSession.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import <Foundation/Foundation.h>
#import "SessionModel.h"
#import "FlappyIM.h"
#import "PostTool.h"
#import "ChatImage.h"
#import "ChatVoice.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyBaseSession : NSObject


//转换为
-(Message*)changeToMessage:(ChatMessage*)chatMsg;

@end

NS_ASSUME_NONNULL_END
