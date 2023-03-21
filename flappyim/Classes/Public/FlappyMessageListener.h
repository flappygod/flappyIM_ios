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


-(void)onSend:(ChatMessage*) msg;

-(void)onUpdate:(ChatMessage*) msg;

-(void)onReceive:(ChatMessage*) msg;


@end

NS_ASSUME_NONNULL_END
