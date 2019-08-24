//
//  FlappySender.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "ChatMessage.h"
#import "FlappyApiRequest.h"
#import "FlappyConfig.h"
#import "Flappy.pbobjc.h"


@interface FlappySender : NSObject

//socket通信
@property (nonatomic,weak) GCDAsyncSocket*  socket;


//单例模式
+ (instancetype)shareInstance;


//上传图片并发送
-(void)uploadImageAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure;

//上传语音并发送
-(void)uploadVoiceAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure;

//上传短视频并发送
-(void)uploadVideoAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure;

//发送消息
-(void)sendMessage:(ChatMessage*)chatMsg
        andSuccess:(FlappySendSuccess)success
        andFailure:(FlappySendFailure)failure;

//成功
-(void)successCallback:(NSInteger)call;

//失败
-(void)failureCallback:(NSInteger)call;

//全部失败
-(void)failureAllCallbacks;


@end
