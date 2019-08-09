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
-(void)addMessageListener:(MessageListener)listener;


//移除消息的监听
-(void)removeMessageListener:(MessageListener)listener;

//清空监听
-(void)clearListeners;


//获取当前最近的一条消息
-(ChatMessage*)getLatestMessage;


//获取某条信息之前的消息
-(NSMutableArray*)getMessagesByOffset:(NSInteger)offset
                             withSize:(NSInteger)size;


@end

NS_ASSUME_NONNULL_END
