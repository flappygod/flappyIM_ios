//
//  Message.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import <SQLitePersistentObject/SQLitePersistentObject.h>

NS_ASSUME_NONNULL_BEGIN

//消息表
@interface Message : SQLitePersistentObject




@property(nonatomic,copy)NSString* messageId;

@property(nonatomic,copy)NSString* messageSession;

@property(nonatomic,copy) NSInteger messageSessionType;

@property(nonatomic,copy) NSInteger messageSessionOffset;

@property(nonatomic,copy) NSInteger messageTableSeq;

@property(nonatomic,copy) NSInteger messageType;

@property(nonatomic,copy)NSString* messageSend;

@property(nonatomic,copy)NSString* messageRecieve;

@property(nonatomic,copy)NSString* messageContent;

@property(nonatomic,copy) NSInteger messageSended;

@property(nonatomic,copy) NSInteger messageReaded;

@property(nonatomic,copy)NSString* messageDate;

@property(nonatomic,copy) NSInteger messageDeleted;

@property(nonatomic,copy)NSString* messageDeletedDate;



@end

NS_ASSUME_NONNULL_END
