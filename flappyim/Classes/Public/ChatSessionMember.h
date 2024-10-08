//
//  SessionDataMember.h
//  flappyim
//
//  Created by li lin on 2024/4/18.
//

#import <Foundation/Foundation.h>
#import "ChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatSessionMember : ChatUser

//会话ID
@property(nonatomic,copy) NSString* sessionId;
//最近阅读
@property(nonatomic,assign) NSInteger sessionMemberLatestRead;
//最近删除
@property(nonatomic,assign) NSInteger sessionMemberLatestDelete;
//标记名称
@property(nonatomic,copy) NSString* sessionMemberMarkName;
//会话免打扰
@property(nonatomic,assign) NSInteger sessionMemberMute;
//会话置顶
@property(nonatomic,assign) NSInteger sessionMemberPinned;
//用户加入时间
@property(nonatomic,copy) NSString* sessionJoinDate;
//用户离开时间
@property(nonatomic,copy) NSString* sessionLeaveDate;
//用户是否离开
@property(nonatomic,assign) NSInteger isLeave;


@end

NS_ASSUME_NONNULL_END
