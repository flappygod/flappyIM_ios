//
//  FlappySession.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import "FlappySession.h"

@implementation FlappySession
{
    NSMutableArray* _listeners;
}

//初始化
-(instancetype)init{
    self=[super init];
    if(self){
        _listeners=[[NSMutableArray alloc]init];
    }
    return self;
}

//设置消息的监听
-(void)setMessageListener:(MessageListener)listener{
    //添加ID
    [[FlappyIM shareInstance] addListener:listener
                            withSessionID: self.session.sessionId];
    [_listeners addObject:listener];
}

//清除
-(void)dealloc{
    [self clearListeners];
}

//清空监听
-(void)clearListeners{
    //移除添加的监听
    if(_listeners!=nil&&_listeners.count>0){
        for(int s=0;s<_listeners.count;s++){
            [[FlappyIM shareInstance] removeListener:[_listeners objectAtIndex:s]];
        }
    }
}


@end
