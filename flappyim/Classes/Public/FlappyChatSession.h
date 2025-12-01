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


//发送文本
-(ChatMessage*)sendText:(NSString*)text
            andReplyMsg:(nullable ChatMessage*)replyMsg
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure;


//发送本地图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure;


//发送本地图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                  andReplyMsg:(nullable ChatMessage*)replyMsg
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure;

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
             andReplyMsg:(nullable ChatMessage*)replyMsg
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;


//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure;

//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                  andReplyMsg:(nullable ChatMessage*)replyMsg
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure;


//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)image
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;


//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)voice
             andReplyMsg:(nullable ChatMessage*)replyMsg
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;


//发送位置
-(ChatMessage*)sendLocation:(ChatLocation*)location
                 andSuccess:(FlappySendSuccess)success
                 andFailure:(FlappySendFailure)failure;

//发送位置信息
-(ChatMessage*)sendLocation:(ChatLocation*)location
                andReplyMsg:(nullable ChatMessage*)replyMsg
                 andSuccess:(FlappySendSuccess)success
                 andFailure:(FlappySendFailure)failure;


//发送本地短视频
-(ChatMessage*)sendLocalVideo:(NSString*)path
                  andReplyMsg:(nullable ChatMessage*)replyMsg
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

//发送视频
-(ChatMessage*)sendVideo:(ChatVideo*)video
             andReplyMsg:(nullable ChatMessage*)replyMsg
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure;


//发送文件
-(ChatMessage*)sendLocalFile:(NSString*)file
                     andName:(NSString*)name
                  andSuccess:(FlappySendSuccess)success
                  andFailure:(FlappySendFailure)failure;

//发送文件
-(ChatMessage*)sendLocalFile:(NSString*)path
                     andName:(NSString*)name
                 andReplyMsg:(nullable ChatMessage*)replyMsg
                  andSuccess:(FlappySendSuccess)success
                  andFailure:(FlappySendFailure)failure;

//发送文件
-(ChatMessage*)sendFile:(ChatFile*)file
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure;

//发送文件
-(ChatMessage*)sendFile:(ChatFile*)file
            andReplyMsg:(nullable ChatMessage*)replyMsg
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure;


//发送自定义
-(ChatMessage*)sendCustom:(NSString*)text
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure;

//发送自定义
-(ChatMessage*)sendCustom:(NSString*)text
              andReplyMsg:(nullable ChatMessage*)replyMsg
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure;


//转发消息到当前会话
-(ChatMessage*)sendForwardMessage:(ChatMessage*)chatmsg
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
-(ChatMessage*)deleteSessionTemporary:(FlappySendSuccess)success
                           andFailure:(FlappySendFailure)failure;

//获取当前最近的一条消息
-(ChatMessage*)getLatestMessage;

//通过消息ID获取消息
-(ChatMessage*)getMessageById:(NSString*) messageId;

//获取某条信息之前的消息
-(NSMutableArray*)getFormerMessages:(NSString*)messageID
                           withSize:(NSInteger)size;

//获取某条信息之后的消息
-(NSMutableArray*)getNewerMessages:(NSString*)messageID
                          withSize:(NSInteger)size;

//搜索消息之前的文本消息
-(NSMutableArray *)searchTextMessage:(NSString*)text
                        andMessageId:(NSString*)messageId
                             andSize:(NSInteger)size;

//搜索消息之前的图片消息
-(NSMutableArray *)searchImageMessage:(NSString*)messageId
                              andSize:(NSInteger)size;


//搜索消息之前的视频消息
-(NSMutableArray *)searchVideoMessage:(NSString*)messageId
                              andSize:(NSInteger)size;

//搜索消息之前的语音消息
-(NSMutableArray *)searchVoiceMessage:(NSString*)messageId
                              andSize:(NSInteger)size;

//获取未读消息数量
-(NSInteger)getUnReadMessageCount;


@end

NS_ASSUME_NONNULL_END
