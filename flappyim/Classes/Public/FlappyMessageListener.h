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
                 andFailure:(MessageListener)failureListener
                  andUpdate:(MessageListener)updateListener
                 andReceive:(MessageListener)receiveListener
                    andRead:(MessageReadListener)readListener
                  andDelete:(MessageDeleteListener)deleteListener;


-(void)onSend:(ChatMessage*) msg;

-(void)onUpdate:(ChatMessage*) msg;

-(void)onReceive:(ChatMessage*) msg;

-(void)onFailure:(ChatMessage*) msg;

-(void)onRead:(NSString*) message;

-(void)onDelete:(NSString*) message;

@end

NS_ASSUME_NONNULL_END
