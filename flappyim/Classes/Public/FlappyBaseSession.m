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

@implementation FlappyBaseSession

//转换为
+(Message*)changeToMessage:(ChatMessage*)chatmsg{
    
    Message* msg=[[Message alloc]init];
    
    msg.messageId=chatmsg.messageId;
    
    msg.messageSession=chatmsg.messageSession;
    
    msg.messageSessionType=(int32_t)chatmsg.messageSessionType;
    
    msg.messageSendId=[chatmsg.messageSendId longLongValue];
    
    msg.messageSendExtendId=chatmsg.messageSendExtendId;
    
    msg.messageReceiveId=[chatmsg.messageReceiveId longLongValue];
    
    msg.messageReceiveExtendId=chatmsg.messageReceiveExtendId;
    
    msg.messageType=(int32_t)chatmsg.messageType;
    
    msg.messageContent=chatmsg.messageContent;
    
    msg.messageDate=chatmsg.messageDate;
    
    msg.messageSendState=(int32_t)chatmsg.messageSendState;
    
    msg.messageReadState=(int32_t)chatmsg.messageReadState;
    
    return msg;
}


@end
