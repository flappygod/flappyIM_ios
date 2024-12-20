//
//  SessionGroupData.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import <Foundation/Foundation.h>
#import "ChatSessionMember.h"
#import "ChatSession.h"


NS_ASSUME_NONNULL_BEGIN

@interface ChatSessionData : ChatSession

@property(nonatomic,strong) NSMutableArray<ChatSessionMember*>*  users;

@property(nonatomic,assign) NSInteger unReadMessageCount;

@property(nonatomic,assign) Boolean isDeleteTemp;

@end

NS_ASSUME_NONNULL_END
