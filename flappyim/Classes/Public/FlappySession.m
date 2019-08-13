//
//  FlappySession.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import "FlappySession.h"
#import "DataBase.h"
#import "DateTimeTool.h"
#import "FlappySender.h"
#import "FlappyConfig.h"
#import "JsonTool.h"
#import "FlappyData.h"
#import "MJExtension.h"

@implementation FlappySession
{
    NSMutableArray* _listeners;
}

//初始化
-(instancetype)init{
    self=[super init];
    if(self){
        _listeners=[[NSMutableArray alloc]init];
    }
    return self;
}

//设置消息的监听
-(void)addMessageListener:(MessageListener)listener{
    //添加ID
    [[FlappyIM shareInstance] addListener:listener
                            withSessionID: self.session.sessionId];
    [_listeners addObject:listener];
}

//清除某个监听
-(void)removeMessageListener:(MessageListener)listener{
    //移除监听
    [[FlappyIM shareInstance] removeListener:listener
                               withSessionID:self.session.sessionId];
    [_listeners removeObject:listener];
}

//销毁的时候清除监听
-(void)dealloc{
    [self clearListeners];
}

//清空监听
-(void)clearListeners{
    //移除添加的监听
    if(_listeners!=nil&&_listeners.count>0){
        for(int s=0;s<_listeners.count;s++){
            [[FlappyIM shareInstance] removeListener:[_listeners objectAtIndex:s]
                                       withSessionID:self.session.sessionId];
        }
    }
}

//获取最近的一条消息
-(ChatMessage*)getLatestMessage{
    //获取消息
    ChatMessage* message=[[DataBase shareInstance]getLatestMessageBySession:self.session.sessionId];
    //返回
    return message;
}


//获取某条信息之前的消息
-(NSMutableArray*)getMessagesByOffset:(NSInteger)offset
                             withSize:(NSInteger)size{
    NSMutableArray* arr=[[DataBase shareInstance]getSessionMessage:self.session.sessionId
                                                        withOffset:offset
                                                          withSize:size];
    return arr;
}


//发送文本
-(ChatMessage*)sendText:(NSString*)text
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure{
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=self.session.userOne.userId;
    chatmsg.messageRecieve=self.session.userTwo.userId;
    chatmsg.messageType=MSG_TYPE_TEXT;
    chatmsg.messageContent=text;
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//发送本地的图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                   andSuccess:(FlappySuccess)success
                   andFailure:(FlappyFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    //创建发送地址
    ChatImage* image=[[ChatImage alloc]init];
    image.sendPath=path;
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=self.session.userOne.userId;
    chatmsg.messageRecieve=self.session.userTwo.userId;
    chatmsg.messageType=MSG_TYPE_IMG;
    chatmsg.messageContent=[JsonTool DicToJSONString:[image mj_keyValues]];
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] uploadImageAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
    
}

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
              andSuccess:(FlappySuccess)success
              andFailure:(FlappyFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=self.session.userOne.userId;
    chatmsg.messageRecieve=self.session.userTwo.userId;
    chatmsg.messageType=MSG_TYPE_IMG;
    chatmsg.messageContent=[JsonTool DicToJSONString:[image mj_keyValues]];
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}


//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                   andSuccess:(FlappySuccess)success
                   andFailure:(FlappyFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    //创建发送地址
    ChatVoice* voice=[[ChatVoice alloc]init];
    voice.sendPath=path;
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=self.session.userOne.userId;
    chatmsg.messageRecieve=self.session.userTwo.userId;
    chatmsg.messageType=MSG_TYPE_IMG;
    chatmsg.messageContent=[JsonTool DicToJSONString:[voice mj_keyValues]];
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] uploadVoiceAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
    
}

//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)voice
              andSuccess:(FlappySuccess)success
              andFailure:(FlappyFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=self.session.userOne.userId;
    chatmsg.messageRecieve=self.session.userTwo.userId;
    chatmsg.messageType=MSG_TYPE_VOICE;
    chatmsg.messageContent=[JsonTool DicToJSONString:[voice mj_keyValues]];
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

@end
