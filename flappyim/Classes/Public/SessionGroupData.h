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

@interface SessionGroupData : ChatSession

@property(nonatomic,strong) NSMutableArray*  users;

@end

NS_ASSUME_NONNULL_END
