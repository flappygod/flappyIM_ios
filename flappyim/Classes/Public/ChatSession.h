//
//  ChatSession.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


//单聊
#define TYPE_SINGLE 1
//群聊
#define TYPE_GROUP 2
//系统
#define TYPE_SYSTEM 3


//会话
@interface ChatSession : NSObject

@property(nonatomic,copy) NSString* sessionId;

@property(nonatomic,copy) NSString* sessionExtendId;

@property(nonatomic,assign) NSInteger sessionType;

@property(nonatomic,copy) NSString* sessionInfo;

@property(nonatomic,copy) NSString* sessionName;

@property(nonatomic,copy) NSString* sessionImage;

@property(nonatomic,copy) NSString* sessionOffset;

@property(nonatomic,copy) NSString* sessionCreateDate;

@property(nonatomic,copy) NSString* sessionCreateUser;

@property(nonatomic,assign) long sessionStamp;

@property(nonatomic,assign) NSInteger isDelete;

@property(nonatomic,copy) NSString* deleteDate;

@property(nonatomic,assign) NSInteger unReadMessageCount;


@end

NS_ASSUME_NONNULL_END
