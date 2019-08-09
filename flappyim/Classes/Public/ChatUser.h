//
//  User.h
//  flappyim
//
//  Created by lijunlin on 2019/8/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//会话的用户
@interface ChatUser : NSObject

//用户ID
@property(nonatomic,copy) NSString* userId;
//用户的扩展ID
@property(nonatomic,copy) NSString* userExtendId;
//用户的名称
@property(nonatomic,copy) NSString* userName;
//用户的头像
@property(nonatomic,copy) NSString* userHead;
//用户的注册时间
@property(nonatomic,copy) NSString* userCreateDate;
//用户是否删除
@property(nonatomic,assign) NSInteger userDeleted;
//用户的删除s日期
@property(nonatomic,copy) NSString* userDeletedDate;
//用户数据
@property(nonatomic,copy) NSString* userData;



//最后的消息序号
@property(nonatomic,copy) NSString* latest;
//是否登录过
@property(nonatomic,assign) Boolean login;



@end

NS_ASSUME_NONNULL_END
