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

//插入数据库
-(void)msgInsert:(ChatMessage*)msg{
    //我们先姑且认为它是最后一条
    ChatUser* user=[FlappyData getUser];
    //创建
    msg.messageSended=SEND_STATE_CREATE;
    //数据
    NSInteger value=(user.latest!=nil? user.latest.integerValue:0)+1;
    //最后一条
    NSString* str=[NSString stringWithFormat:@"%ld",(long)value];
    //还没发送成功，那么放在最后一条
    msg.messageTableSeq=str;
    //之前有没有
    ChatMessage* former=[[DataBase shareInstance] getMessageByID:msg.messageId];
    //没有就插入，有就更新
    if(former==nil){
        [[DataBase shareInstance] insert:msg];
    }else{
        [[DataBase shareInstance] updateMessage:msg];
    }
}


//发送文本
-(ChatMessage*)sendText:(NSString*)text
             andSuccess:(FlappySuccess)success
             andFailure:(FlappyFailure)failure{
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.2f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=self.session.userOne.userId;
    chatmsg.messageRecieve=self.session.userTwo.userId;
    chatmsg.messageType=MSG_TYPE_TEXT;
    chatmsg.messageContent=text;
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    //转换一下
    Message* msg=[self changeToMessage:chatmsg];
    
    //插入消息
    [self msgInsert:chatmsg];
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:msg
                                  withChatMsg:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//发送本地的图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                   andSuccess:(FlappySuccess)success
                   andFailure:(FlappyFailure)failure{
    
}

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
              andSuccess:(FlappySuccess)success
              andFailure:(FlappyFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.2f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=self.session.userOne.userId;
    chatmsg.messageRecieve=self.session.userTwo.userId;
    chatmsg.messageType=MSG_TYPE_IMG;
    chatmsg.messageContent=[JsonTool DicToJSONString:[image mj_keyValues]];
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    Message* msg=[self changeToMessage:chatmsg];
    
    [self msgInsert:chatmsg];
    
    [[FlappySender shareInstance] sendMessage:msg
                                  withChatMsg:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}

//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)voice
              andSuccess:(FlappySuccess)success
              andFailure:(FlappyFailure)failure{
    
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    Message* msg=[[Message alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.2f",[[NSDate new] timeIntervalSince1970]];
    chatmsg.messageSession=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSend=self.session.userOne.userId;
    chatmsg.messageRecieve=self.session.userTwo.userId;
    chatmsg.messageType=MSG_TYPE_VOICE;
    chatmsg.messageContent=[JsonTool DicToJSONString:[voice mj_keyValues]];
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSended=SEND_STATE_CREATE;
    
    
    Message* msg=[self changeToMessage:chatmsg];
    
    [self msgInsert:chatmsg];
    
    [[FlappySender shareInstance] sendMessage:msg
                                  withChatMsg:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

@end
