//
//  ChatGroupSession.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import <Foundation/Foundation.h>
#import "SessionGroupData.h"
#import "FlappyIM.h"
#import "PostTool.h"
#import "ChatImage.h"
#import "ChatVoice.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatGroupSession : NSObject


//群组的数据
@property(nonatomic,strong) SessionGroupData*  session;


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


//发送文本
-(ChatMessage*)sendText:(NSString*)text
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure;


//发送本地图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                   andSuccess:(FlappySuccess)success
                   andFailure:(FlappyFailure)failure;

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
              andSuccess:(FlappySuccess)success
              andFailure:(FlappyFailure)failure;


//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                   andSuccess:(FlappySuccess)success
                   andFailure:(FlappyFailure)failure;


//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)image
              andSuccess:(FlappySuccess)success
              andFailure:(FlappyFailure)failure;


//重新发送
-(void)resendMessage:(ChatMessage*)chatmsg
          andSuccess:(FlappySuccess)success
          andFailure:(FlappyFailure)failure;

@end

NS_ASSUME_NONNULL_END
