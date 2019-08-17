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
@property (nonatomic,strong) GCDAsyncSocket*  socket;


//单例模式
+ (instancetype)shareInstance;


//上传图片并发送
-(void)uploadImageAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure;


-(void)uploadVoiceAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure;

//发送消息
-(void)sendMessage:(ChatMessage*)chatMsg
        andSuccess:(FlappySuccess)success
        andFailure:(FlappyFailure) failure;

//成功
-(void)successCallback:(NSInteger)call;

//失败
-(void)failureCallback:(NSInteger)call;

//全部失败
-(void)failureAllCallbacks;


@end
