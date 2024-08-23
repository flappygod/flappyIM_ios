//
//  FlappySessionListener.h
//  flappyim
//
//  Created by li lin on 2024/8/19.
//

#import <Foundation/Foundation.h>
#import "FlappyBlocks.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappySessionListener : NSObject

//初始化
-(instancetype)initWithReceiveList:(SessionListListener)receiveListListener
                        andReceive:(SessionListener)receiveListener
                     andUpdateList:(SessionListListener)updateListListener
                         andUpdate:(SessionListener)updateListener
                         andDelete:(SessionListener)deleteListener;

-(void)onReceiveList:(NSArray*) sessionList;

-(void)onReceive:(ChatSessionData*) session;

-(void)onUpdateList:(NSArray*) sessionList;

-(void)onUpdate:(ChatSessionData*) session;

-(void)onDelete:(ChatSessionData*) session;



@end

NS_ASSUME_NONNULL_END
