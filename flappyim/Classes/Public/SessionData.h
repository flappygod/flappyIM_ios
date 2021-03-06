//
//  SessionGroupData.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import <Foundation/Foundation.h>
#import "ChatSession.h"
#import "ChatUser.h"


NS_ASSUME_NONNULL_BEGIN

@interface SessionData : ChatSession

@property(nonatomic,strong) NSMutableArray<ChatUser*>*  users;

@end

NS_ASSUME_NONNULL_END
