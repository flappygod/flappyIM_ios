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
#import "FlappyConfig.h"
#import "Flappy.pbobjc.h"


@interface FlappySender : NSObject

//socket通信
@property (nonatomic,strong) GCDAsyncSocket*  socket;


//单例模式
+ (instancetype)shareInstance;


//发送消息
-(void)sendMessage:(Message*)msg
       withChatMsg:(ChatMessage*)chatMsg
        andSuccess:(FlappySuccess)success
        andFailure:(FlappyFailure) failure;

//成功
-(void)successCallback:(NSInteger)call;

//失败
-(void)failureCallback:(NSInteger)call;

//全部失败
-(void)failureCallbacks;


@end
