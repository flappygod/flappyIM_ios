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

//初始化
-(instancetype)initWithSend:(MessageListener)sendListener
                 andFailure:(MessageListener)failureListener
                  andUpdate:(MessageListener)updateListener
                 andReceive:(MessageListener)receiveListener
                  andDelete:(MessageListener)deleteListener
               andReadOther:(MessageReadListener)otherReadListener
                andReadSelf:(MessageReadListener)readListener;

-(void)onSend:(ChatMessage*) msg;

-(void)onUpdate:(ChatMessage*) msg;

-(void)onReceive:(ChatMessage*) msg;

-(void)onFailure:(ChatMessage*) msg;

-(void)onDelete:(ChatMessage*) message;


-(void)onOtherRead:(NSString*)sessionId
       andReaderId:(NSString*)readerId
        andSequece:(NSString*)tableSequece;

-(void)onSelfRead:(NSString*)sessionId
      andReaderId:(NSString*)readerId
       andSequece:(NSString*)tableSequece;


@end

NS_ASSUME_NONNULL_END
