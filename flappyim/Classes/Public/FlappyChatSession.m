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
    }
    else if(self.session.sessionType==TYPE_GROUP){
        return self.session.sessionId;
    }
    else if(self.session.sessionType==TYPE_SYSTEM){
        return @"0";
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
    }
    else if(self.session.sessionType==TYPE_GROUP){
        return self.session.sessionExtendId;
    }
    else if(self.session.sessionType==TYPE_SYSTEM){
        return @"0";
    }
    return nil;
}

//检查是否可以发送
-(Boolean)checkMsgCantSend:(FlappySendFailure)failure{
    
    ///获取当前会话的状态，只包含自己的user
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    ChatSessionData* currentData = [[FlappyDataBase shareInstance] getUserSessionOnlyCurrentUserById:self.session.sessionId
                                                                                           andUserId:mine.userId];
    ///用户已经离开了
    if(currentData.users.count > 0){
        ChatSessionMember* user =[currentData.users objectAtIndex:0];
        if([user.userId isEqualToString:mine.userId] && user.isLeave == 1){
            failure(nil,[NSError errorWithDomain:@"User leaved" code:0 userInfo:nil],RESULT_SESSION_MEMBER_UNABLE);
            return true;
        }
    }
    ///不可用了
    if(currentData.isEnable == 0){
        failure(nil,[NSError errorWithDomain:@"Session unable" code:0 userInfo:nil],RESULT_SESSION_UNABLE);
        return true;
    }
    ///已经删除了
    if(currentData.isDelete == 1){
        failure(nil,[NSError errorWithDomain:@"Session deleted" code:0 userInfo:nil],RESULT_SESSION_DELETED);
        return true;
    }
    return false;
}

//发送文本
-(void)setMessageReply:(nullable ChatMessage*)replyMsg
            forMessage:(ChatMessage*)message{
    if(replyMsg==nil){
        return;
    }
    [message setMessageReplyMsgId:replyMsg.messageId];
    [message setMessageReplyUserId:replyMsg.messageSendId];
    [message setMessageReplyMsgType:replyMsg.messageType];
    [message setMessageReplyMsgContent:replyMsg.messageContent];
}

//发送文本
-(ChatMessage*)sendText:(NSString*)text
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure{
    return [self sendText:text
             andAtUserIds:nil
              andReplyMsg:nil
               andSuccess:success
               andFailure:failure];
}

//发送文本
-(ChatMessage*)sendText:(NSString*)text
           andAtUserIds:(nullable NSArray<NSString*>*)userIds
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure{
    return [self sendText:text
             andAtUserIds:(NSArray*)userIds
              andReplyMsg:nil
               andSuccess:success
               andFailure:failure];
}

//发送文本
-(ChatMessage*)sendText:(NSString*)text
          andAtUserIds:(nullable NSArray<NSString*>*)userIds
           andReplyMsg:(nullable ChatMessage*)replyMsg
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure{
    
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
    
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
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageSendState=SEND_STATE_SENDING;
    if(userIds!=nil && userIds.count>0){
        chatmsg.messageAtUserIds = [userIds componentsJoinedByString:@","];
    }
    [chatmsg setChatText:text];
    
    //设置回复消息
    [self setMessageReply: replyMsg
               forMessage:chatmsg];
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//发送本地图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    return [self sendLocalImage:path
                    andReplyMsg:nil
                     andSuccess:success
                     andFailure:failure];
}


//发送本地的图片
-(ChatMessage*)sendLocalImage:(NSString*)path
                  andReplyMsg:(nullable ChatMessage*)replyMsg
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
    
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    [[FlappySender shareInstance] uploadImageAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
    
}


//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    return  [self sendImage:image
                andReplyMsg:nil
                 andSuccess:success
                 andFailure:failure];
}

//发送图片
-(ChatMessage*)sendImage:(ChatImage*)image
             andReplyMsg:(nullable ChatMessage*)replyMsg
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}

//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    return [self sendLocalVoice:path
                    andReplyMsg:nil
                     andSuccess:success
                     andFailure:failure];
}


//发送本地的图片
-(ChatMessage*)sendLocalVoice:(NSString*)path
                  andReplyMsg:(nullable ChatMessage*)replyMsg
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    [[FlappySender shareInstance] uploadVoiceAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
    
}

//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)voice
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    return  [self sendVoice:voice
                andReplyMsg:nil
                 andSuccess:success
                 andFailure:failure];
}

//发送语音
-(ChatMessage*)sendVoice:(ChatVoice*)voice
             andReplyMsg:(nullable ChatMessage*)replyMsg
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//发送位置信息
-(ChatMessage*)sendLocation:(ChatLocation*)location
                 andSuccess:(FlappySendSuccess)success
                 andFailure:(FlappySendFailure)failure{
    return  [self sendLocation:location
                   andReplyMsg:nil
                    andSuccess:success
                    andFailure:failure];
}

//发送位置信息
-(ChatMessage*)sendLocation:(ChatLocation*)location
                andReplyMsg:(nullable ChatMessage*)replyMsg
                 andSuccess:(FlappySendSuccess)success
                 andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}

//发送本地video
-(ChatMessage*)sendLocalVideo:(NSString*)path
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    return [self sendLocalVideo:path
                    andReplyMsg:nil
                     andSuccess:success
                     andFailure:failure];
}


//发送本地短视频
-(ChatMessage*)sendLocalVideo:(NSString*)path
                  andReplyMsg:(nullable ChatMessage*)replyMsg
                   andSuccess:(FlappySendSuccess)success
                   andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
    
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    [[FlappySender shareInstance] uploadVideoAndSend:chatmsg
                                          andSuccess:success
                                          andFailure:failure];
    return chatmsg;
}

//发送视频
-(ChatMessage*)sendVideo:(ChatVideo*)video
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    return  [self sendVideo:video
                andReplyMsg:nil
                 andSuccess:success
                 andFailure:failure];
}


//发送视频
-(ChatMessage*)sendVideo:(ChatVideo*)video
             andReplyMsg:(nullable ChatMessage*)replyMsg
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
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
    return [self sendLocalFile:path
                       andName:name
                   andReplyMsg:nil
                    andSuccess:success
                    andFailure:failure];
}


//发送文件
-(ChatMessage*)sendLocalFile:(NSString*)path
                     andName:(NSString*)name
                 andReplyMsg:(nullable ChatMessage*)replyMsg
                  andSuccess:(FlappySendSuccess)success
                  andFailure:(FlappySendFailure)failure{
    
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
    
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    [[FlappySender shareInstance] uploadFileAndSend:chatmsg
                                         andSuccess:success
                                         andFailure:failure];
    return chatmsg;
}

//发送文件
-(ChatMessage*)sendFile:(ChatFile*)file
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure{
    return  [self sendFile:file
               andReplyMsg:nil
                andSuccess:success
                andFailure:failure];
}


//发送文件
-(ChatMessage*)sendFile:(ChatFile*)file
            andReplyMsg:(nullable ChatMessage*)replyMsg
             andSuccess:(FlappySendSuccess)success
             andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
    
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    return chatmsg;
}


//发送自定义
-(ChatMessage*)sendCustom:(NSString*)text
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure{
    return [self sendCustom:text
                andReplyMsg:nil
                 andSuccess:success
                 andFailure:failure];
}


//发送自定义
-(ChatMessage*)sendCustom:(NSString*)text
              andReplyMsg:(nullable ChatMessage*)replyMsg
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure{
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
    
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
    
    //设置回复消息
    [self setMessageReply:replyMsg
               forMessage:chatmsg];
    
    //发送消息
    [[FlappySender shareInstance] sendMessage:chatmsg
                                   andSuccess:success
                                   andFailure:failure];
    
    return chatmsg;
}

//转发消息
-(ChatMessage*)sendForwardMessage:(ChatMessage*)chatmsg
                       andSuccess:(FlappySendSuccess)success
                       andFailure:(FlappySendFailure)failure{
    
    //不能发送
    if([self checkMsgCantSend:failure]){
        return nil;
    }
    
    ChatUser* mine = [[FlappyData shareInstance] getUser];
    chatmsg.messageId=[FlappyStringTool uuidString];
    chatmsg.messageSessionId=self.session.sessionId;
    chatmsg.messageSessionType=self.session.sessionType;
    chatmsg.messageSendId=mine.userId;
    chatmsg.messageSendExtendId=mine.userExtendId;
    chatmsg.messageReceiveId=[self getPeerID];
    chatmsg.messageReceiveExtendId=[self getPeerExtendID];
    chatmsg.messageDate=[FlappyDateTool formatNorMalTimeStrFromDate:[NSDate new]];
    chatmsg.messageForwardTitle = @"Forward";
    chatmsg.messageReplyMsgId = @"";
    chatmsg.messageReplyMsgType = 0;
    chatmsg.messageReplyMsgContent = @"";
    chatmsg.messageReplyUserId = @"";
    
    chatmsg.messageDeleteUserIds = @"";
    chatmsg.messageRecallUserId = @"";
    chatmsg.messageReadUserIds = @"";
    chatmsg.messageDeleteUserIds = @"";
    
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
-(ChatMessage*)deleteSessionTemporary:(FlappySendSuccess)success
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
    action.actionType=ACTION_TYPE_SESSION_DELETE_TEMP;
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
    
    //不能发送
    if([self checkMsgCantSend:failure]){
        return;
    }
    
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

//通过消息ID获取消息
-(ChatMessage*)getMessageById:(NSString*) messageId{
    //获取消息
    ChatMessage* message=[[FlappyDataBase shareInstance] getMessageById:messageId];
    //返回
    return message;
}

//获取所有@我的消息（支持分页）
- (NSMutableArray *)getAllAtMeMessages:(NSString *)sessionID
                            incluedAll:(BOOL)includeAll
                                  page:(NSInteger)page
                                  size:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]
                         getAllAtMeMessages:self.session.sessionId
                         incluedAll:true
                         page:page
                         size:size];
    return arr;
}

//获取未读的at我的消息
-(NSMutableArray*)getUnReadAtMeMessages:(Boolean)includeAll
                               withSize:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]
                         getUnReadAtMeMessages:self.session.sessionId
                         incluedAll:true
                         withSize:size];
    return arr;
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


//获取某条信息之后的消息
-(NSMutableArray*)getNewerMessages:(NSString*)messageID
                          withSize:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]
                         getSessionNewerMessages:self.session.sessionId
                         withMessageID:messageID
                         withSize:size];
    return arr;
}

//搜索消息之前的文本消息
-(NSMutableArray *)searchTextMessage:(NSString*)text
                        andMessageId:(NSString*)messageId
                             andSize:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]
                         searchTextMessage:text
                         andSessionId:self.session.sessionId
                         andMessageId:messageId
                         andSize:size];
    return arr;
}

//搜索消息之前的图片消息
-(NSMutableArray *)searchImageMessage:(NSString*)messageId
                              andSize:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]
                         searchImageMessage:self.session.sessionId
                         andMessageId:messageId
                         andSize:size];
    return arr;
}

//搜索消息之前的视频消息
-(NSMutableArray *)searchVideoMessage:(NSString*)messageId
                              andSize:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]
                         searchVideoMessage:self.session.sessionId
                         andMessageId:messageId
                         andSize:size];
    return arr;
}


//搜索消息之前的语音消息
-(NSMutableArray *)searchVoiceMessage:(NSString*)messageId
                              andSize:(NSInteger)size{
    NSMutableArray* arr=[[FlappyDataBase shareInstance]
                         searchVoiceMessage:self.session.sessionId
                         andMessageId:messageId
                         andSize:size];
    return arr;
}


//获取未读消息数量
-(NSInteger)getUnReadMessageCount{
    return  [[FlappyDataBase shareInstance] getUnReadSessionMessageCountBySessionId:self.session.sessionId];
}


@end
