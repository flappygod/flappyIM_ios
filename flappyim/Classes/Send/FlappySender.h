//
//  FlappySender.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "ChatMessage.h"
#import "PostTool.h"
#import "Flappy.pbobjc.h"


@interface FlappySender : NSObject

//socket通信
@property (nonatomic,strong) GCDAsyncSocket*  socket;

//成功
@property(nonatomic,strong) NSMutableDictionary* successCallbacks;

//失败
@property(nonatomic,strong) NSMutableDictionary* failureCallbacks;


//单例模式
+ (instancetype)shareInstance;

@end
