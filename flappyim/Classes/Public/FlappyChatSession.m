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
#import "FlappyStringTool.h"
#import "FlappyImageTool.h"
#import "FlappyApiConfig.h"
#import "FlappyData.h"
#import "MJExtension.h"

@implementation FlappyChatSession
{
    NSMutableArray* _messageListeners;
}

//初始化
-(instancetype)init{
    self=[super init];
    if(self){
        _messageListeners=[[NSMutableArray alloc]init];
    }
    return self;
}


//获取对方的ID
-(NSString*)getPeerID{
    if(self.session.sessionType==TYPE_SINGLE){
        ChatUser* mine = [[FlappyData shareInstance] getUser];
        for(int s=0;s<self.session.users.count;s++){
            ChatUser* user=[self.session.users objectAtIndex:s];
            if(![user.userId isEqualToString:mine.userId]){
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
        ChatUser* mine = [[FlappyData shareInstance] getUser];
        for(int s=0;s<self.session.users.count;s++){
            ChatUser* user=[self.session.users objectAtIndex:s];
            if(![user.userId isEqualToString:mine.userId]){
                return user.userExtendId;
            }
        }
    }else if(self.session.sessionType==TYPE_GROUP){
        return self.session.sessionExtendId;
    }
    return nil;
}


//设置消息的监听
-(void)addMessageListener:(FlappyMessageListener*)listener{
    //添加ID
    [_messageListeners addObject:listener];
    [[FlappyIM shareInstance] addMsgListener:listener
                               withSessionID:self.session.sessionId];
}

//清除某个监听
-(void)removeMessageListener:(FlappyMessageListener*)listener{
    //添加ID
    [_messageListeners removeObject:listener];
    [[FlappyIM shareInstance] removeMsgListener:listener
                                  withSessionID:self.session.sessionId];
}

//销毁的时候清除监听
-(void)dealloc{
    [self clearListeners];
}

//清空监听
-(void)clearListeners{
    //移除添加的监听
    if(_messageListeners!=nil&&_messageListeners.count>0){
        for(int s=0;s<_messageListeners.count;s++){
            [[FlappyIM shareInstance] removeMsgListener:[_messageListeners objectAtIndex:s]
                                          withSessionID:self.session.sessionId];
        }
    }
}


//发送文本
-(ChatMessage*)sendText:(NSString*)text
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure{
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_TEXT;
    [chatmsg setChatText:text];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
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
    
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_IMG;
    //本地发送的地址
    ChatImage* image=[[ChatImage alloc]init];
    image.sendPath=path;
    [chatmsg setChatImage:image];
    
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] uploadImageAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
    
}

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    
    //消息
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_IMG;
    [chatmsg setChatImage:image];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}


//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_VOICE;
    //创建发送地址
    ChatVoice* voice=[[ChatVoice alloc]init];
    voice.sendPath=path;
    [chatmsg setChatVoice:voice];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] uploadVoiceAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
    
}

//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)voice
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_VOICE;
    [chatmsg setChatVoice:voice];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//发送位置信息
-(ChatMessage*)sendLocation:(ChatLocation*)location
                 andSuccess:(FlappySendSuccess)success
                 andFailure:(FlappySendFailure)failure{
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_LOCATE;
    [chatmsg setChatLocation:location];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}


//发送本地短视频
-(ChatMessage*)sendLocalVideo:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_VIDEO;
    //创建发送地址
    ChatVideo* video=[[ChatVideo alloc]init];
    video.sendPath=path;
    [chatmsg setChatVideo:video];
    
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] uploadVideoAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
}


//发送视频
-(ChatMessage*)sendVideo:(ChatVideo*)video
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_VIDEO;
    [chatmsg setChatVideo:video];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}


//发送文件
-(ChatMessage*)sendLocalFile:(NSString*)path
                     andName:(NSString*)name
                  andSuccess:(FlappySendSuccess)success
                  andFailure:(FlappySendFailure)failure{
    
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    
    //创建发送地址
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    ChatFile* file=[[ChatFile alloc]init];
    file.sendPath=path;
    file.fileName=name;
    
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_FILE;
    [chatmsg setChatFile:file];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] uploadFileAndSend:chatmsg
                                         andSuccess:success
                                         andFailure:failure];
    return chatmsg;
}


//发送文件
-(ChatMessage*)sendFile:(ChatFile*)file
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure{
    
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_FILE;
    [chatmsg setChatFile:file];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}


//发送自定义
-(ChatMessage*)sendCustom:(NSString*)text
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure{
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_CUSTOM;
    [chatmsg setChatCustom:text];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//发送已读消息
-(ChatMessage*)sessionMessageRead:(FlappySendSuccess)success
                       andFailure:(FlappySendFailure)failure{
    
    //没有未读的消息
    if([self getUnReadMessageCount]==0){
        if(success!=nil){
            success(nil);
        }
        return  nil;
    }
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    
    //创建阅读的消息
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_ACTION;
    
    ChatAction* action=[[ChatAction alloc]init];
    action.actionType=ACTION_TYPE_SESSION_READ;
    action.actionIds=@[
        mine.userId,
        self.session.sessionId,
        [NSString stringWithFormat:@"%ld",[self getLatestMessage].messageTableOffset]
    ];
    [chatmsg setChatAction:action];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}


//修改mute
-(ChatMessage*)sessionChangeMute:(NSInteger)mute
                      andSuccess:(FlappySendSuccess)success
                      andFailure:(FlappySendFailure)failure{
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    
    //创建阅读的消息
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_ACTION;
    
    ChatAction* action=[[ChatAction alloc]init];
    action.actionType=ACTION_TYPE_SESSION_MUTE;
    action.actionIds=@[
        mine.userId,
        self.session.sessionId,
        [NSString stringWithFormat:@"%ld",mute]
    ];
    [chatmsg setChatAction:action];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}


//修改Pinned
-(ChatMessage*)sessionChangePinned:(NSInteger)pinned
                        andSuccess:(FlappySendSuccess)success
                        andFailure:(FlappySendFailure)failure{
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    
    //创建阅读的消息
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_ACTION;
    
    ChatAction* action=[[ChatAction alloc]init];
    action.actionType=ACTION_TYPE_SESSION_PIN;
    action.actionIds=@[
        mine.userId,
        self.session.sessionId,
        [NSString stringWithFormat:@"%ld",pinned]
    ];
    [chatmsg setChatAction:action];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}


//删除会话
-(ChatMessage*)sessionDelete:(Boolean)permanent
                  andSuccess:(FlappySendSuccess)success
                  andFailure:(FlappySendFailure)failure{
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    
    //创建阅读的消息
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_ACTION;
    
    //最近的消息
    ChatMessage* message = [self getLatestMessage];
    long sessionOffset = (message!=nil ? message.messageSessionOffset : 0);
    
    //消息
    ChatAction* action=[[ChatAction alloc]init];
    action.actionType=permanent ? ACTION_TYPE_SESSION_DELETE_PERMANENT:ACTION_TYPE_SESSION_DELETE_TEMP;
    action.actionIds=@[
        mine.userId,
        self.session.sessionId,
        [NSString stringWithFormat:@"%ld",sessionOffset]
    ];
    [chatmsg setChatAction:action];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}



//撤回已经发送的消息
-(ChatMessage*)deleteMessageById:(NSString*)messageId
                      andSuccess:(FlappySendSuccess)success
                      andFailure:(FlappySendFailure)failure{
    
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_ACTION;
    
    ChatAction* action=[[ChatAction alloc]init];
    action.actionType=ACTION_TYPE_MSG_DELETE;
    action.actionIds=@[
        mine.userId,
        self.session.sessionId,
        messageId
    ];
    [chatmsg setChatAction:action];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}


//撤回已经发送的消息
-(ChatMessage*)recallMessageById:(NSString*)messageId
                      andSuccess:(FlappySendSuccess)success
                      andFailure:(FlappySendFailure)failure{
    
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageType=MSG_TYPE_ACTION;
    
    ChatAction* action=[[ChatAction alloc]init];
    action.actionType=ACTION_TYPE_MSG_RECALL;
    action.actionIds=@[
        mine.userId,
        self.session.sessionId,
        messageId
    ];
    [chatmsg setChatAction:action];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//重新发送
-(void)resendMessageById:(NSString*)messageId
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    ChatMessage* message = [[FlappyDataBase shareInstance] getMessageById:messageId];
    [self resendMessage:message andSuccess:success andFailure:failure];
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
    else if(chatmsg.messageType==MSG_TYPE_LOCATE){
        [[FlappySender shareInstance] sendMessage:chatmsg
                                       andSuccess:success
                                       andFailure:failure];
    }
    //重新发送视频消息
    else if(chatmsg.messageType==MSG_TYPE_VIDEO){
        [[FlappySender shareInstance] uploadVideoAndSend:chatmsg
                                              andSuccess:success
                                              andFailure:failure];
    }
    //重新发送文件消息
    else if(chatmsg.messageType==MSG_TYPE_FILE){
        [[FlappySender shareInstance] uploadFileAndSend:chatmsg
                                             andSuccess:success
                                             andFailure:failure];
    }
    //重新发送自定义消息
    else if(chatmsg.messageType==MSG_TYPE_CUSTOM){
        [[FlappySender shareInstance] sendMessage:chatmsg
                                       andSuccess:success
                                       andFailure:failure];
    }
}

//获取最近的一条消息
-(ChatMessage*)getLatestMessage{
    //获取消息
    ChatMessage* message=[[FlappyDataBase shareInstance]getSessionLatestMessage:self.session.sessionId];
    //返回
    return message;
}

//获取某条信息之前的消息
-(NSMutableArray*)getFormerMessages:(NSString*)messageID
                           withSize:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]
                         getSessionFormerMessages:self.session.sessionId
                         withMessageID:messageID
                         withSize:size];
    return arr;
}

//获取未读消息数量
-(NSInteger)getUnReadMessageCount{
    return  [[FlappyDataBase shareInstance] getUnReadSessionMessageCountBySessionId:self.session.sessionId];
}


@end
