//
//  FlappyBaseSession.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import "FlappyBaseSession.h"
#import "FlappyDataBase.h"
#import "FlappyDateTool.h"
#import "FlappySender.h"
#import "FlappyConfig.h"
#import "FlappyJsonTool.h"
#import "FlappyData.h"
#import "MJExtension.h"
#import "Aes128.h"

@implementation FlappyBaseSession

//转换为
+(Message*)changeToMessage:(ChatMessage*)chatmsg
          andChannelSecret:(NSString*) channelSecret{
    
    Message* msg=[[Message alloc]init];
    
    msg.messageId=chatmsg.messageId;
    
    msg.messageSessionId=[chatmsg.messageSessionId longLongValue];
    
    msg.messageSessionType=(int32_t)chatmsg.messageSessionType;
    
    msg.messageSessionOffset=chatmsg.messageSessionOffset;
    
    msg.messageTableOffset=chatmsg.messageTableOffset;
    
    msg.messageSendId=[chatmsg.messageSendId longLongValue];
    
    msg.messageSendExtendId=chatmsg.messageSendExtendId;
    
    msg.messageReceiveId=[chatmsg.messageReceiveId longLongValue];
    
    msg.messageReceiveExtendId=chatmsg.messageReceiveExtendId;
    
    msg.messageType=(int32_t)chatmsg.messageType;
    
    
    ///状态区
    msg.messageSendState=(int32_t)chatmsg.messageSendState;
    
    msg.messageReadState=(int32_t)chatmsg.messageReadState;
    
    msg.messagePinState=(int32_t)chatmsg.messagePinState;
    
    ///回复区
    msg.messageReplyMsgId=chatmsg.messageReplyMsgId;
    
    msg.messageReplyMsgType=(int32_t)chatmsg.messageReplyMsgType;
    
    msg.messageReplyUserId=chatmsg.messageReplyUserId;
    
    msg.messageForwardTitle=chatmsg.messageForwardTitle;
    
    ///ID区
    msg.messageRecallUserId=chatmsg.messageRecallUserId;
    
    msg.messageAtUserIds=chatmsg.messageAtUserIds;
    
    msg.messageReadUserIds=chatmsg.messageReadUserIds;
    
    msg.messageDeleteUserIds=chatmsg.messageDeleteUserIds;
    
    ///基本
    msg.messageDate=chatmsg.messageDate;
    
    msg.isDelete=(int32_t)chatmsg.isDelete;
    
    msg.deleteDate=chatmsg.deleteDate;
    
    
    
    //消息体、秘钥加密
    msg.messageContent = [Aes128 AES128Encrypt:chatmsg.messageContent
                                               withKey:chatmsg.messageSecret];
    msg.messageReplyMsgContent = [Aes128 AES128Encrypt:chatmsg.messageReplyMsgContent
                                                       withKey:chatmsg.messageSecret];
    msg.messageSecret = [Aes128 AES128Encrypt:chatmsg.messageSecret
                                              withKey:channelSecret];
    
    
    return msg;
}


@end
