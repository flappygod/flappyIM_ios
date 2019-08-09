//
//  FlappySession.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import "FlappySession.h"

@implementation FlappySession
{
    NSMutableArray* listeners;
}



//设置消息的监听
-(void)setMessageListener:(MessageListener)listener{
    //[[FlappyIM shareInstance] addListener:listener withSessionID: self.];
}

//清除
-(void)dealloc{
    
}


@end
