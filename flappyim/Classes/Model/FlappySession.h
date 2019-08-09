//
//  FlappySession.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import "SessionModel.h"
#import "FlappyIM.h"
#import "PostTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappySession : NSObject

//用户
@property(nonatomic,copy) NSString*  userOne;
//用户
@property(nonatomic,copy) NSString*  userTwo;
//session
@property(nonatomic,strong) SessionModel*  session;


//设置消息的监听
-(void)setMessageListener:(MessageListener)listener;


@end

NS_ASSUME_NONNULL_END
