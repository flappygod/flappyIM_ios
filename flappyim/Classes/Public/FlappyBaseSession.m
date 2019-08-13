//
//  FlappyBaseSession.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import "FlappyBaseSession.h"
#import "DataBase.h"
#import "DateTimeTool.h"
#import "FlappySender.h"
#import "FlappyConfig.h"
#import "JsonTool.h"
#import "FlappyData.h"
#import "MJExtension.h"

@implementation FlappyBaseSession

//转换为
+(Message*)changeToMessage:(ChatMessage*)chatMsg{
    
    Message* msg=[[Message alloc]init];
    
    msg.messageId=chatmsg.messageId;
    
    msg.messageSession=chatmsg.messageSession;
    
    msg.messageSessionType=(int32_t)chatmsg.messageSessionType;
    
    msg.messageSend=chatmsg.messageSend;
    
    msg.messageRecieve=chatmsg.messageRecieve;
    
    msg.messageType=(int32_t)chatmsg.messageType;
    
    msg.messageContent=chatmsg.messageContent;
    
    msg.messageDate=chatmsg.messageDate;
    
    msg.messageSended=(int32_t)chatmsg.messageSended;
    
    return msg;
}


@end
