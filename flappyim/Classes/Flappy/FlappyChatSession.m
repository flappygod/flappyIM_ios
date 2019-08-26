//
//  ChatSingleSession.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import "FlappyChatSession.h"
#import "FlappyDataBase.h"
#import "FlappyDateTool.h"
#import "FlappySender.h"
#import "FlappyConfig.h"
#import "FlappyJsonTool.h"
#import "FlappyData.h"
#import "MJExtension.h"

@implementation FlappyChatSession
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


//获取当前的用户
-(ChatUser*)getMine{
    return [[FlappyData shareInstance]getUser];
}

//获取对方的ID
-(NSString*)getPeerID{
    if(self.session.sessionType==TYPE_SINGLE){
        for(int s=0;s<self.session.users.count;s++){
            ChatUser* user=[self.session.users objectAtIndex:s];
            if(![user.userId isEqualToString:[self getMine].userId]){
                return user.userId;
            }
        }
    }else if(self.session.sessionType==TYPE_GROUP){
        return self.session.sessionId;
    }
    return nil;
}

//对方的ID
-(NSString*)getPeerExtendID{
    if(self.session.sessionType==TYPE_SINGLE){
        for(int s=0;s<self.session.users.count;s++){
            ChatUser* user=[self.session.users objectAtIndex:s];
            if(![user.userId isEqualToString:[self getMine].userId]){
                return user.userExtendId;
            }
        }
    }else if(self.session.sessionType==TYPE_GROUP){
        return self.session.sessionExtendId;
    }
    return nil;
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
    ChatMessage* message=[[FlappyDataBase shareInstance]getLatestMessageBySession:self.session.sessionId];
    //返回
    return message;
}


//获取某条信息之前的消息
-(NSMutableArray*)getMessagesByOffset:(NSInteger)offset
                             withSize:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]getSessionMessage:self.session.sessionId
                                                        withOffset:offset
                                                          withSize:size];
    return arr;
}


//发送文本
-(ChatMessage*)sendText:(NSString*)text
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure{
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=[self getMine].userId;
    chatmsg.messageSendExtendid=[self getMine].userExtendId;
    chatmsg.messageRecieve=[self getPeerID];
    chatmsg.messageRecieveExtendid=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_TEXT;
    [chatmsg setChatText:text];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//发送本地的图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    //创建发送地址
    ChatImage* image=[[ChatImage alloc]init];
    image.sendPath=path;
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=[self getMine].userId;
    chatmsg.messageSendExtendid=[self getMine].userExtendId;
    chatmsg.messageRecieve=[self getPeerID];
    chatmsg.messageRecieveExtendid=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_IMG;
    chatmsg.messageContent=[FlappyJsonTool DicToJSONString:[image mj_keyValues]];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] uploadImageAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
    
}

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=[self getMine].userId;
    chatmsg.messageSendExtendid=[self getMine].userExtendId;
    chatmsg.messageRecieve=[self getPeerID];
    chatmsg.messageRecieveExtendid=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_IMG;
    chatmsg.messageContent=[FlappyJsonTool DicToJSONString:[image mj_keyValues]];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}


//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    //创建发送地址
    ChatVoice* voice=[[ChatVoice alloc]init];
    voice.sendPath=path;
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=[self getMine].userId;
    chatmsg.messageSendExtendid=[self getMine].userExtendId;
    chatmsg.messageRecieve=[self getPeerID];
    chatmsg.messageRecieveExtendid=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_IMG;
    chatmsg.messageContent=[FlappyJsonTool DicToJSONString:[voice mj_keyValues]];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] uploadVoiceAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
    
}

//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)voice
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=[self getMine].userId;
    chatmsg.messageSendExtendid=[self getMine].userExtendId;
    chatmsg.messageRecieve=[self getPeerID];
    chatmsg.messageRecieveExtendid=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_VOICE;
    chatmsg.messageContent=[FlappyJsonTool DicToJSONString:[voice mj_keyValues]];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//发送本地短视频
-(ChatMessage*)sendLocalVideo:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    //创建发送地址
    ChatVideo* voice=[[ChatVideo alloc]init];
    voice.sendPath=path;
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=[self getMine].userId;
    chatmsg.messageSendExtendid=[self getMine].userExtendId;
    chatmsg.messageRecieve=[self getPeerID];
    chatmsg.messageRecieveExtendid=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_VIDEO;
    chatmsg.messageContent=[FlappyJsonTool DicToJSONString:[voice mj_keyValues]];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] uploadVideoAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
}


//发送视频
-(ChatMessage*)sendVideo:(ChatVideo*)video
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=[self getMine].userId;
    chatmsg.messageSendExtendid=[self getMine].userExtendId;
    chatmsg.messageRecieve=[self getPeerID];
    chatmsg.messageRecieveExtendid=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_VIDEO;
    chatmsg.messageContent=[FlappyJsonTool DicToJSONString:[video mj_keyValues]];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}


//发送位置信息
-(ChatMessage*)sendLocation:(ChatLocation*)location
                 andSuccess:(FlappySendSuccess)success
                 andFailure:(FlappySendFailure)failure{
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.3f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=[self getMine].userId;
    chatmsg.messageSendExtendid=[self getMine].userExtendId;
    chatmsg.messageRecieve=[self getPeerID];
    chatmsg.messageRecieveExtendid=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_LOCATE;
    chatmsg.messageContent=[FlappyJsonTool DicToJSONString:[location mj_keyValues]];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}

//重新发送
-(void)resendMessage:(ChatMessage*)chatmsg
          andSuccess:(FlappySendSuccess)success
          andFailure:(FlappySendFailure)failure{
    //重新发送文本消息
    if(chatmsg.messageType==MSG_TYPE_TEXT){
        [[FlappySender shareInstance] sendMessage:chatmsg
                                       andSuccess:success
                                       andFailure:failure];
    }
    //重新发送图片消息
    else if(chatmsg.messageType==MSG_TYPE_IMG){
        
        
        [[FlappySender shareInstance] uploadImageAndSend:chatmsg
                                              andSuccess:success
                                              andFailure:failure];
        
    }
    //重新发送语音消息
    else if(chatmsg.messageType==MSG_TYPE_VOICE){
        
        [[FlappySender shareInstance] uploadVoiceAndSend:chatmsg
                                              andSuccess:success
                                              andFailure:failure];
    }
    //重新发送位置消息
    if(chatmsg.messageType==MSG_TYPE_LOCATE){
        [[FlappySender shareInstance] sendMessage:chatmsg
                                       andSuccess:success
                                       andFailure:failure];
    }
    
}


@end
