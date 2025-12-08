//
//  ChatMessage.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import "FlappyStringTool.h"
#import "FlappyJsonTool.h"
#import "ChatMessage.h"
#import "MJExtension.h"
#import "FMDatabase.h"
#import "Aes128.h"

@implementation ChatMessage


- (instancetype)init {
    //调用父类的初始化方法
    self = [super init];
    if (self) {
        _messageSecret = [FlappyStringTool RandomString:16];
    }
    //返回实例
    return self;
}


//通过result初始化
- (instancetype)initWithResult:(FMResultSet *)result {
    self = [super init];
    if (self) {
        
        ///基础ID区
        _messageId = [result stringForColumn:@"messageId"];
        _messageSessionId = [result stringForColumn:@"messageSessionId"];
        _messageSessionType = [result intForColumn:@"messageSessionType"];
        _messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        _messageTableOffset = [result intForColumn:@"messageTableOffset"];
        
        ///发送接收区
        _messageType = [result intForColumn:@"messageType"];
        _messageSendId = [result stringForColumn:@"messageSendId"];
        _messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        _messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        _messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        
        ///消息状态区
        _messageSendState = [result intForColumn:@"messageSendState"];
        _messageReadState = [result intForColumn:@"messageReadState"];
        _messagePinState = [result intForColumn:@"messagePinState"];
        _messageStamp = [result longForColumn:@"messageStamp"];
        
        ///回复区
        _messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
        _messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
        _messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
        _messageForwardTitle = [result stringForColumn:@"messageForwardTitle"];
        
        ///操作ID区
        _messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
        _messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
        _messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
        _messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
        
        ///基础区
        _messageDate = [result stringForColumn:@"messageDate"];
        _isDelete = [result intForColumn:@"isDelete"];
        _deleteDate = [result stringForColumn:@"deleteDate"];
        
        ///内容区
        _messageSecret = [result stringForColumn:@"messageSecret"];
        _messageContent = [result stringForColumn:@"messageContent"];
        _messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
    }
    return self;
}


//设置|获取系统消息
-(void)setChatSystem:(ChatSystem*)chatSystem{
    if(chatSystem!=nil){
        _messageContent = [FlappyJsonTool jsonObjectToJsonStr:[chatSystem mj_keyValues]];
    }
}
-(ChatSystem*)getChatSystem{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_SYSTEM){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:_messageContent];
        return [ChatSystem mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取回执
-(void)setReadReceipt:(ChatReadReceipt*)receipt{
    if(receipt!=nil){
        _messageContent = [FlappyJsonTool jsonObjectToJsonStr:[receipt mj_keyValues]];
    }
}
-(ChatReadReceipt*)getReadReceipt{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_READ_RECEIPT){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:_messageContent];
        return [ChatReadReceipt mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取动作
-(void)setChatAction:(ChatAction*)chatAction{
    if(chatAction!=nil){
        _messageContent = [FlappyJsonTool jsonObjectToJsonStr:[chatAction mj_keyValues]];
    }
}
-(ChatAction*)getChatAction{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_ACTION){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:_messageContent];
        return [ChatAction mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取文本
-(void)setChatText:(NSString*)chatText{
    if(chatText!=nil){
        _messageContent= chatText;
    }
}
-(NSString*)getChatText{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_TEXT){
        return _messageContent;
    }
    return nil;
}


//设置|获取图像
-(void)setChatImage:(ChatImage*)chatImage{
    if(chatImage!=nil){
        _messageContent=[FlappyJsonTool jsonObjectToJsonStr:[chatImage mj_keyValues]];
    }
}
-(ChatImage*)getChatImage{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_IMG){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:_messageContent];
        return [ChatImage mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取声音
-(void)setChatVoice:(ChatVoice*)chatVoice{
    if(chatVoice!=nil){
        _messageContent=[FlappyJsonTool jsonObjectToJsonStr:[chatVoice mj_keyValues]];
    }
}
-(ChatVoice*)getChatVoice{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VOICE){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:_messageContent];
        return [ChatVoice mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取视频
-(void)setChatVideo:(ChatVideo*)chatVideo{
    if(chatVideo!=nil){
        _messageContent=[FlappyJsonTool jsonObjectToJsonStr:[chatVideo mj_keyValues]];
    }
}
-(ChatVideo*)getChatVideo{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VIDEO){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:_messageContent];
        return [ChatVideo mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取位置
-(void)setChatLocation:(ChatLocation*)chatLocation{
    if(chatLocation!=nil){
        _messageContent=[FlappyJsonTool jsonObjectToJsonStr:[chatLocation mj_keyValues]];
    }
}
-(ChatLocation*)getChatLocation{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_LOCATE){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:_messageContent];
        return [ChatLocation mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取文件
-(void)setChatFile:(ChatFile*)chatFile{
    if(chatFile!=nil){
        _messageContent=[FlappyJsonTool jsonObjectToJsonStr:[chatFile mj_keyValues]];
    }
}
-(ChatFile*)getChatFile{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_FILE){
        NSDictionary* dic=[FlappyJsonTool jsonStrToObject:_messageContent];
        return [ChatFile mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取自定义
-(void)setChatCustom:(NSString*)chatText{
    if(chatText!=nil){
        _messageContent= chatText;
    }
}
-(NSString*)getChatCustom{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_CUSTOM){
        return _messageContent;
    }
    return nil;
}



@end
