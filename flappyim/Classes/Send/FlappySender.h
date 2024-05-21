//
//  FlappySender.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "FlappyApiRequest.h"
#import "Flappy.pbobjc.h"
#import "FlappyConfig.h"
#import "FlappySocket.h"
#import "ChatMessage.h"


@interface FlappySender : NSObject

//socket通信
@property (nonatomic,weak) FlappySocket*  flappySocket;

//消息
@property(nonatomic,strong) NSMutableDictionary* sendingMessages;


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

//上传文件并发送
-(void)uploadFileAndSend:(ChatMessage*)chatMsg
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;

//发送消息
-(void)sendMessage:(ChatMessage*)chatMsg
        andSuccess:(FlappySendSuccess)success
        andFailure:(FlappySendFailure)failure;

//成功
-(void)handleSendSuccessCallback:(ChatMessage*)messageid;

//失败
-(void)handleSendFailureCallback:(ChatMessage*)message;

//全部失败
-(void)handleSendFailureAllCallback;

//消息已读回执和删除回执,对方的阅读消息存在的时候才会执行
-(void)handleMessageAction:(ChatMessage*)message;


//通知消息插入
-(void)notifyMessageSendInsert:(ChatMessage*)msg;


//通知消息接收
-(void)notifyMessageReceive:(ChatMessage*)msg
                  andFormer:(ChatMessage*)former;

//通知消息失败
-(void)notifyMessageFailure:(ChatMessage*)msg;

//会话
-(void)notifySession:(SessionData*)session;


@end
