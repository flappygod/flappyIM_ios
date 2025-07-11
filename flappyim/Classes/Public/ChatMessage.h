//
//  ChatMessage.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import "ChatLocation.h"
#import "ChatAction.h"
#import "ChatSystem.h"
#import "ChatImage.h"
#import "ChatVoice.h"
#import "ChatVideo.h"
#import "ChatFile.h"

NS_ASSUME_NONNULL_BEGIN


//消息被创建
#define SEND_STATE_SENDING   0
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
//动作类消息
#define MSG_TYPE_ACTION  8



//撤回消息
#define ACTION_TYPE_MSG_RECALL  1
//删除消息
#define ACTION_TYPE_MSG_DELETE  2
//会话已读
#define ACTION_TYPE_SESSION_READ  3
//会话静音
#define ACTION_TYPE_SESSION_MUTE  4
//会话置顶
#define ACTION_TYPE_SESSION_PIN  5
//会话删除临时
#define ACTION_TYPE_SESSION_DELETE_TEMP  6
//会话删除全部
#define ACTION_TYPE_SESSION_DELETE_PERMANENT  7



//会话的消息
@interface ChatMessage : NSObject


@property(nonatomic,copy) NSString* messageId;

@property(nonatomic,copy) NSString* messageSessionId;

@property(nonatomic,assign) NSInteger messageSessionType;

@property(nonatomic,assign) NSInteger messageSessionOffset;

@property(nonatomic,assign) NSInteger messageTableOffset;

@property(nonatomic,assign) NSInteger messageType;

@property(nonatomic,copy)NSString* messageSendId;

@property(nonatomic,copy)NSString* messageSendExtendId;

@property(nonatomic,copy)NSString* messageReceiveId;

@property(nonatomic,copy)NSString* messageReceiveExtendId;

@property(nonatomic,copy)NSString* messageContent;

@property(nonatomic,assign) NSInteger messageSendState;

@property(nonatomic,assign) NSInteger messageReadState;

@property(nonatomic,assign) NSInteger messagePinState;

@property(nonatomic,copy)NSString* messageSecret;

@property(nonatomic,copy)NSString* messageDate;

@property(nonatomic,assign) NSInteger messageStamp;

@property(nonatomic,assign) NSInteger isDelete;

@property(nonatomic,copy)NSString* messageReplyMsgId;

@property(nonatomic,assign) NSInteger messageReplyMsgType;

@property(nonatomic,copy)NSString* messageReplyMsgContent;

@property(nonatomic,copy)NSString* messageReplyUserId;

@property(nonatomic,copy)NSString* messageForwardTitle;

@property(nonatomic,copy)NSString* messageRecallUserId;

@property(nonatomic,copy)NSString* messageAtUserIds;

@property(nonatomic,copy)NSString* messageReadUserIds;

@property(nonatomic,copy)NSString* messageDeleteUserIds;

@property(nonatomic,copy)NSString* deleteDate;

//初始化
- (instancetype)init;

//初始化
- (instancetype)initWithResult:(id)result;


//聊天文本
-(void)setChatText:(NSString*)chatText;
-(NSString*)getChatText;


//系统消息
-(void)setChatSystem:(ChatSystem*)chatSystem;
-(ChatSystem*)getChatSystem;

//图片
-(void)setChatImage:(ChatImage*)chatImage;
-(ChatImage*)getChatImage;

//声音
-(void)setChatVoice:(ChatVoice*)chatVoice;
-(ChatVoice*)getChatVoice;

//位置
-(void)setChatLocation:(ChatLocation*)chatLocation;
-(ChatLocation*)getChatLocation;

//视频
-(void)setChatVideo:(ChatVideo*)chatVideo;
-(ChatVideo*)getChatVideo;

//文件
-(void)setChatFile:(ChatFile*)chatFile;
-(ChatFile*)getChatFile;

//动作
-(void)setChatAction:(ChatAction*)chatFile;
-(ChatAction*)getChatAction;

//自定义
-(void)setChatCustom:(NSString*)chatText;
-(NSString*)getChatCustom;



@end

NS_ASSUME_NONNULL_END
