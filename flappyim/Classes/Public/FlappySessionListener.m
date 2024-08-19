//
//  FlappySessionListener.m
//  flappyim
//
//  Created by li lin on 2024/8/19.
//

#import "FlappySessionListener.h"

@implementation FlappySessionListener
{
    SessionListListener _receiveListListener;
    SessionListener _receiveListener;
    SessionListener _deleteListener;
}

///init with listeners
-(instancetype)initWithReceiveList:(SessionListListener)receiveListListener
                        andReceive:(SessionListener)receiveListener
                         andDelete:(SessionListener)deleteListener{
    self=[super init];
    if(self){
        _receiveListListener=receiveListListener;
        _receiveListener=receiveListener;
        _deleteListener=_deleteListener;
    }
    return self;
}

-(void)onReceiveList:(NSArray*) sessionList{
    if(_receiveListListener!=nil){
        _receiveListListener(sessionList);
    }
}

-(void)onReceive:(SessionData*) session{
    if(_receiveListener!=nil){
        _receiveListener(session);
    }
}

-(void)onDelete:(SessionData*) session{
    if(_deleteListener!=nil){
        _deleteListener(session);
    }
}




@end
