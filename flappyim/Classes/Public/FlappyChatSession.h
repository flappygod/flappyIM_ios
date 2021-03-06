//
//  ChatSingleSession.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import "SessionData.h"
#import "FlappyIM.h"
#import "FlappyApiRequest.h"
#import "ChatImage.h"
#import "ChatVoice.h"
#import "ChatLocation.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyChatSession : NSObject


//session
@property(nonatomic,strong) SessionData*  session;


//设置消息的监听
-(void)addMessageListener:(MessageListener)listener;


//移除消息的监听
-(void)removeMessageListener:(MessageListener)listener;


//清空监听
-(void)clearListeners;


//获取当前最近的一条消息
-(ChatMessage*)getLatestMessage;


//获取某条信息之前的消息
-(NSMutableArray*)getFormerMessages:(NSString*)messageID
                             withSize:(NSInteger)size;


//发送文本
-(ChatMessage*)sendText:(NSString*)text
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure;


//发送本地图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure;

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;


//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure;


//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)image
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;



//发送视频
-(ChatMessage*)sendLocalVideo:(NSString*)video
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure;


//发送视频
-(ChatMessage*)sendVideo:(ChatVideo*)video
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;


//发送位置
-(ChatMessage*)sendLocation:(ChatLocation*)location
                 andSuccess:(FlappySendSuccess)success
                 andFailure:(FlappySendFailure)failure;


//重新发送
-(void)resendMessage:(ChatMessage*)chatmsg
          andSuccess:(FlappySendSuccess)success
          andFailure:(FlappySendFailure)failure;


@end

NS_ASSUME_NONNULL_END
