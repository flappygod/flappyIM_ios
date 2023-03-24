//
//  FlappyMessageListener.m
//  flappyim
//
//  Created by li lin on 2023/3/21.
//

#import "FlappyMessageListener.h"
#import "ChatMessage.h"

@implementation FlappyMessageListener
{
    MessageListener _sendListener;
    MessageListener _updateListener;
    MessageListener _receiveListener;
    MessageListener _failureListener;
}

///init with blocks
-(instancetype)initWithSend:(MessageListener)sendListener
                 andFailure:(MessageListener)failureListener
                  andUpdate:(MessageListener)updateListener
                 andReceive:(MessageListener)receiveListener{
    self=[super init];
    if(self){
        _sendListener=sendListener;
        _failureListener=failureListener;
        _updateListener=updateListener;
        _receiveListener=receiveListener;
    }
    return self;
}

-(void)onSend:(ChatMessage*) msg{
    if(_sendListener!=nil){
        _sendListener(msg);
    }
}

-(void)onUpdate:(ChatMessage*) msg{
    if(_updateListener!=nil){
        _updateListener(msg);
    }
}

-(void)onReceive:(ChatMessage*) msg{
    if(_receiveListener!=nil){
        _receiveListener(msg);
    }
}

-(void)onFailure:(ChatMessage*) msg{
    if(_failureListener!=nil){
        _failureListener(msg);
    }
}


@end
