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

NS_ASSUME_NONNULL_BEGIN


//消息被创建
#define SEND_STATE_CREATE   0
//消息已经发送
#define SEND_STATE_SENDED   1
//消息已经到达
#define SEND_STATE_REACHED  3
//消息发送失败
#define SEND_STATE_FAILURE  9




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



//会话的消息
@interface ChatMessage : NSObject


@property(nonatomic,copy) NSString* messageId;

@property(nonatomic,copy) NSString* messageSession;

@property(nonatomic,assign) NSInteger messageSessionType;

@property(nonatomic,assign) NSInteger messageSessionOffset;

@property(nonatomic,assign) NSInteger messageTableSeq;

@property(nonatomic,assign) NSInteger messageType;

@property(nonatomic,copy)NSString* messageSend;

@property(nonatomic,copy)NSString* messageSendExtendid;

@property(nonatomic,copy)NSString* messageRecieve;

@property(nonatomic,copy)NSString* messageRecieveExtendid;

@property(nonatomic,copy)NSString* messageContent;

@property(nonatomic,assign) NSInteger messageSended;

@property(nonatomic,assign) NSInteger messageReaded;

@property(nonatomic,copy)NSString* messageDate;

@property(nonatomic,assign) NSInteger messageDeleted;

@property(nonatomic,assign) NSInteger messageStamp;

@property(nonatomic,copy)NSString* messageDeletedDate;



//设置聊天文本
-(void)setChatText:(NSString*)chatText;


//获取聊天文本
-(NSString*)getChatText;

//获取图像
-(ChatImage*)getChatImage;

//获取声音
-(ChatVoice*)getChatVoice;

//获取视频
-(ChatVideo*)getChatVideo;

//获取位置
-(ChatLocation*)getChatLocation;


@end

NS_ASSUME_NONNULL_END
