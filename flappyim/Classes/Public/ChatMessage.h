//
//  ChatMessage.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



//文本消息
#define MSG_TYPE_TEXT  @"1"
//图片消息
#define MSG_TYPE_IMG  @"2"
//语音消息
#define MSG_TYPE_VOICE  @"3"
//表情消息
#define MSG_TYPE_EMOJ  @"4"
//红包消息
#define MSG_TYPE_REDBACKET  @"5"



//会话的消息
@interface ChatMessage : NSObject


@property(nonatomic,copy) NSString* messageId;

@property(nonatomic,copy) NSString* messageSession;

@property(nonatomic,assign) NSInteger messageSessionType;

@property(nonatomic,assign) NSInteger messageSessionOffset;

@property(nonatomic,assign) NSString* messageTableSeq;

@property(nonatomic,assign) NSInteger messageType;

@property(nonatomic,copy)NSString* messageSend;

@property(nonatomic,copy)NSString* messageRecieve;

@property(nonatomic,copy)NSString* messageContent;

@property(nonatomic,assign) NSInteger messageSended;

@property(nonatomic,assign) NSInteger messageReaded;

@property(nonatomic,copy)NSString* messageDate;

@property(nonatomic,assign) NSInteger messageDeleted;

@property(nonatomic,copy)NSString* messageDeletedDate;

@end

NS_ASSUME_NONNULL_END
