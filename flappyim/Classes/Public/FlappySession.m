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
-(void)sendText:(NSString*)text
     andSuccess:(FlappySuccess)success
     andFailure:(FlappyFailure)failure{
    
    GCDAsyncSocket* socket=[FlappySender shareInstance].socket;
    
    //错误了
    if(socket==nil){
        failure([NSError errorWithDomain:@"连接已断开" code:0 userInfo:nil],RESULT_NETERROR);
        return;
    }
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    Message* msg=[[Message alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.2f",[[NSDate new] timeIntervalSince1970]];
    msg.messageId=chatmsg.messageId;
    
    chatmsg.messageSession=self.session.sessionId;
    msg.messageSession=chatmsg.messageSession;
    
    chatmsg.messageSessionType=self.session.sessionType;
    msg.messageSessionType=(int32_t)chatmsg.messageSessionType;
    
    chatmsg.messageSend=self.session.userOne.userId;
    msg.messageSend=chatmsg.messageSend;
    
    chatmsg.messageRecieve=self.session.userTwo.userId;
    msg.messageRecieve=chatmsg.messageRecieve;
    
    chatmsg.messageType=MSG_TYPE_TEXT;
    msg.messageType=(int32_t)chatmsg.messageType;
    
    chatmsg.messageContent=text;
    msg.messageContent=chatmsg.messageContent;
    
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    msg.messageDate=chatmsg.messageDate;
    
    //连接到服务器开始请求登录
    FlappyRequest* request=[[FlappyRequest alloc]init];
    //登录请求
    request.type=REQ_MSG;
    //登录信息
    request.msg=msg;
    
    //请求数据，已经GPBComputeRawVarint32SizeForInteger
    NSData* reqData=[request delimitedData];
    //写入请求数据
    [socket writeData:reqData withTimeout:-1 tag:0];
    
    //成功
    success(chatmsg);
    
}

//发送图片
-(void)sendImage:(ChatImage*)image
      andSuccess:(FlappySuccess)success
      andFailure:(FlappyFailure)failure{
    
    GCDAsyncSocket* socket=[FlappySender shareInstance].socket;
    
    //错误了
    if(socket==nil){
        failure([NSError errorWithDomain:@"连接已断开" code:0 userInfo:nil],RESULT_NETERROR);
        return;
    }
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    Message* msg=[[Message alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.2f",[[NSDate new] timeIntervalSince1970]];
    msg.messageId=chatmsg.messageId;
    
    chatmsg.messageSession=self.session.sessionId;
    msg.messageSession=chatmsg.messageSession;
    
    chatmsg.messageSessionType=self.session.sessionType;
    msg.messageSessionType=(int32_t)chatmsg.messageSessionType;
    
    chatmsg.messageSend=self.session.userOne.userId;
    msg.messageSend=chatmsg.messageSend;
    
    chatmsg.messageRecieve=self.session.userTwo.userId;
    msg.messageRecieve=chatmsg.messageRecieve;
    
    chatmsg.messageType=MSG_TYPE_IMG;
    msg.messageType=(int32_t)chatmsg.messageType;
    
    chatmsg.messageContent=[JsonTool DicToJSONString:[image mj_keyValues]];
    msg.messageContent=chatmsg.messageContent;
    
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    msg.messageDate=chatmsg.messageDate;
    
    //连接到服务器开始请求登录
    FlappyRequest* request=[[FlappyRequest alloc]init];
    //登录请求
    request.type=REQ_MSG;
    //登录信息
    request.msg=msg;
    
    //请求数据，已经GPBComputeRawVarint32SizeForInteger
    NSData* reqData=[request delimitedData];
    //写入请求数据
    [socket writeData:reqData withTimeout:-1 tag:0];
    
    //成功
    success(chatmsg);
}

//发送语音
-(void)sendVoice:(ChatVoice*)voice
      andSuccess:(FlappySuccess)success
      andFailure:(FlappyFailure)failure{
    
    GCDAsyncSocket* socket=[FlappySender shareInstance].socket;
    //错误了
    if(socket==nil){
        failure([NSError errorWithDomain:@"连接已断开" code:0 userInfo:nil],RESULT_NETERROR);
        return;
    }
    
    ChatMessage* chatmsg=[[ChatMessage alloc]init];
    Message* msg=[[Message alloc]init];
    
    chatmsg.messageId=[NSString stringWithFormat:@"%.2f",[[NSDate new] timeIntervalSince1970]];
    msg.messageId=chatmsg.messageId;
    
    chatmsg.messageSession=self.session.sessionId;
    msg.messageSession=chatmsg.messageSession;
    
    chatmsg.messageSessionType=self.session.sessionType;
    msg.messageSessionType=(int32_t)chatmsg.messageSessionType;
    
    chatmsg.messageSend=self.session.userOne.userId;
    msg.messageSend=chatmsg.messageSend;
    
    chatmsg.messageRecieve=self.session.userTwo.userId;
    msg.messageRecieve=chatmsg.messageRecieve;
    
    chatmsg.messageType=MSG_TYPE_VOICE;
    msg.messageType=(int32_t)chatmsg.messageType;
    
    chatmsg.messageContent=[JsonTool DicToJSONString:[voice mj_keyValues]];
    msg.messageContent=chatmsg.messageContent;
    
    chatmsg.messageDate=[DateTimeTool formatNorMalTimeStrFromDate:[NSDate new]];
    msg.messageDate=chatmsg.messageDate;
    
    //连接到服务器开始请求登录
    FlappyRequest* request=[[FlappyRequest alloc]init];
    //登录请求
    request.type=REQ_MSG;
    //登录信息
    request.msg=msg;
    
    //请求数据，已经GPBComputeRawVarint32SizeForInteger
    NSData* reqData=[request delimitedData];
    //写入请求数据
    [socket writeData:reqData withTimeout:-1 tag:0];
    
    //成功
    success(chatmsg);
}

@end
