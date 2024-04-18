//
//  SessionGroupData.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import <Foundation/Foundation.h>
#import "SessionDataMember.h"
#import "ChatSession.h"


NS_ASSUME_NONNULL_BEGIN

@interface SessionData : ChatSession

@property(nonatomic,strong) NSMutableArray<SessionDataMember*>*  users;

@end

NS_ASSUME_NONNULL_END
