//
//  FlappyMessageListener.h
//  flappyim
//
//  Created by li lin on 2023/3/21.
//

#import <Foundation/Foundation.h>
#import "FlappyBlocks.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyMessageListener : NSObject

-(instancetype)initWithSend:(MessageListener)sendListener
                  andUpdate:(MessageListener)updateListener
                 andReceive:(MessageListener)receiveListener;


@end

NS_ASSUME_NONNULL_END
