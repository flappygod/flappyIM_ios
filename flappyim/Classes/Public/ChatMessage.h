//
//  ChatMessage.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "ChatImage.h"
#import "ChatVoice.h"
#import "ChatVideo.h"
#import "ChatLocation.h"
#import "ChatSystem.h"
#import "ChatFile.h"

NS_ASSUME_NONNULL_BEGIN


//消息被创建
#define SEND_STATE_CREATE   0
//消息已经发送
#define SEND_STATE_SENDED   1
//消息已经到达
#define SEND_STATE_REACHED  3
//消息发送失败
#define SEND_STATE_FAILURE  9



//系统消息
#define MSG_TYPE_SYSTEM  0
//文本消息
#define MSG_TYPE_TEXT  1
//图片消息
#define MSG_TYPE_IMG  2
//语音消息
#define MSG_TYPE_VOICE  3
//位置消息
#define MSG_TYPE_LOCATE  4
//短视频
#define MSG_TYPE_VIDEO  5
//文件
#define MSG_TYPE_FILE  6
//自定义消息
#define MSG_TYPE_CUSTOM  7



//会话的消息
@interface ChatMessage : NSObject


@property(nonatomic,copy) NSString* messageId;

@property(nonatomic,copy) NSString* messageSession;

@property(nonatomic,assign) NSInteger messageSessionType;

@property(nonatomic,assign) NSInteger messageSessionOffset;

@property(nonatomic,assign) NSInteger messageTableSeq;

@property(nonatomic,assign) NSInteger messageType;

@property(nonatomic,copy)NSString* messageSendId;

@property(nonatomic,copy)NSString* messageSendExtendId;

@property(nonatomic,copy)NSString* messageReceiveId;

@property(nonatomic,copy)NSString* messageReceiveExtendId;

@property(nonatomic,copy)NSString* messageContent;

@property(nonatomic,assign) NSInteger messageSendState;

@property(nonatomic,assign) NSInteger messageReadState;

@property(nonatomic,copy)NSString* messageDate;

@property(nonatomic,assign) NSInteger messageStamp;

@property(nonatomic,assign) NSInteger isDelete;

@property(nonatomic,copy)NSString* deleteDate;


//设置聊天文本
-(void)setChatText:(NSString*)chatText;
//获取聊天文本
-(NSString*)getChatText;


//设置系统消息
-(void)setChatSystem:(ChatSystem*)chatSystem;
//获取系统消息
-(ChatSystem*)getChatSystem;


//设置图像
-(void)setChatImage:(ChatImage*)chatImage;
//获取图像
-(ChatImage*)getChatImage;


//设置声音
-(void)setChatVoice:(ChatVoice*)chatVoice;
//获取声音
-(ChatVoice*)getChatVoice;

//设置位置
-(void)setChatLocation:(ChatLocation*)chatLocation;
//获取位置
-(ChatLocation*)getChatLocation;

//设置视频
-(void)setChatVideo:(ChatVideo*)chatVideo;
//获取视频
-(ChatVideo*)getChatVideo;

//设置文件
-(void)setChatFile:(ChatFile*)chatFile;
//获取文件
-(ChatFile*)getChatFile;



@end

NS_ASSUME_NONNULL_END
