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
    SessionListListener _updateListListener;
    SessionListener _updateListener;
    SessionListener _deleteListener;
}

///init with listeners
-(instancetype)initWithReceiveList:(SessionListListener)receiveListListener
                        andReceive:(SessionListener)receiveListener
                     andUpdateList:(SessionListListener)updateListListener
                         andUpdate:(SessionListener)updateListener
                         andDelete:(SessionListener)deleteListener{
    self=[super init];
    if(self){
        _receiveListListener=receiveListListener;
        _receiveListener=receiveListener;
        _updateListListener =updateListListener;
        _updateListener=updateListener;
        _deleteListener=deleteListener;
    }
    return self;
}

-(void)onReceiveList:(NSArray*) sessionList{
    if(_receiveListListener!=nil){
        _receiveListListener(sessionList);
    }
}

-(void)onReceive:(ChatSessionData*) session{
    if(_receiveListener!=nil){
        _receiveListener(session);
    }
}

-(void)onUpdateList:(NSArray*) sessionList{
    if(_updateListListener!=nil){
        _updateListListener(sessionList);
    }
}

-(void)onUpdate:(ChatSessionData*) session{
    if(_updateListener!=nil){
        _updateListener(session);
    }
}

-(void)onDelete:(ChatSessionData*) session{
    if(_deleteListener!=nil){
        _deleteListener(session);
    }
}




@end
