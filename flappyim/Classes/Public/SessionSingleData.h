//
//  SessionModel.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import "ChatSession.h"
#import "ChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface SessionSingleData : ChatSession

//用户一
@property(nonatomic,strong) ChatUser*  userOne;
//用户二
@property(nonatomic,strong) ChatUser*  userTwo;


@end

NS_ASSUME_NONNULL_END
