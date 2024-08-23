//
//  ChatSingleSession.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import "FlappyMessageListener.h"
#import "FlappyApiRequest.h"
#import "ChatSessionData.h"
#import "ChatLocation.h"
#import "ChatImage.h"
#import "ChatVoice.h"
#import "ChatVideo.h"
#import "ChatFile.h"
#import "FlappyIM.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyChatSession : NSObject


//session
@property(nonatomic,strong) ChatSessionData*  session;


//设置消息的监听
-(void)addMessageListener:(FlappyMessageListener*)listener;


//移除消息的监听
-(void)removeMessageListener:(FlappyMessageListener*)listener;


//清空监听
-(void)clearListeners;


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


//发送位置
-(ChatMessage*)sendLocation:(ChatLocation*)location
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


//发送文件
-(ChatMessage*)sendLocalFile:(NSString*)file
                     andName:(NSString*)name
                  andSuccess:(FlappySendSuccess)success
                  andFailure:(FlappySendFailure)failure;


//发送文件
-(ChatMessage*)sendFile:(ChatFile*)file
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure;


//发送自定义
-(ChatMessage*)sendCustom:(NSString*)text
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure;


//删除会话消息
-(ChatMessage*)recallMessageById:(NSString*)messageId
                      andSuccess:(FlappySendSuccess)success
                      andFailure:(FlappySendFailure)failure;


//通过消息ID删除消息
-(ChatMessage*)deleteMessageById:(NSString*)messageId
                      andSuccess:(FlappySendSuccess)success
                      andFailure:(FlappySendFailure)failure;


//重新发送
-(void)resendMessageById:(NSString*)messageId
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;


//重新发送
-(void)resendMessage:(ChatMessage*)chatmsg
          andSuccess:(FlappySendSuccess)success
          andFailure:(FlappySendFailure)failure;


//消息发送已读
-(ChatMessage*)sessionMessageRead:(FlappySendSuccess)success
                       andFailure:(FlappySendFailure)failure;


//修改mute
-(ChatMessage*)sessionChangeMute:(NSInteger)mute
                      andSuccess:(FlappySendSuccess)success
                      andFailure:(FlappySendFailure)failure;

//修改Pinned
-(ChatMessage*)sessionChangePinned:(NSInteger)pinned
                        andSuccess:(FlappySendSuccess)success
                        andFailure:(FlappySendFailure)failure;

//删除会话
-(ChatMessage*)sessionDelete:(Boolean)permanent
                  andSuccess:(FlappySendSuccess)success
                  andFailure:(FlappySendFailure)failure;

//获取当前最近的一条消息
-(ChatMessage*)getLatestMessage;


//获取某条信息之前的消息
-(NSMutableArray*)getFormerMessages:(NSString*)messageID
                           withSize:(NSInteger)size;


//获取未读消息数量
-(NSInteger)getUnReadMessageCount;


@end

NS_ASSUME_NONNULL_END
