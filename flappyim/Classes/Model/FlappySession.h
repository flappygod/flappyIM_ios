//
//  FlappySession.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import "FlappyIM.h"
#import "PostTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappySession : NSObject


//设置消息的监听
-(void)setMessageListener:(MessageListener*)listener;


@end

NS_ASSUME_NONNULL_END
