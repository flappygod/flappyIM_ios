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


//设置|获取系统消息
-(void)setChatSystem:(ChatSystem*)chatSystem{
    if(chatSystem!=nil){
        _messageContent = [FlappyJsonTool DicToJSONString:[chatSystem mj_keyValues]];
    }
}
-(ChatSystem*)getChatSystem{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_SYSTEM){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        return [ChatSystem mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取动作
-(void)setChatAction:(ChatAction*)chatAction{
    if(chatAction!=nil){
        _messageContent = [FlappyJsonTool DicToJSONString:[chatAction mj_keyValues]];
    }
}
-(ChatAction*)getChatAction{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_ACTION){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
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
        _messageContent=[FlappyJsonTool DicToJSONString:[chatImage mj_keyValues]];
    }
}
-(ChatImage*)getChatImage{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_IMG){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        return [ChatImage mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取声音
-(void)setChatVoice:(ChatVoice*)chatVoice{
    if(chatVoice!=nil){
        _messageContent=[FlappyJsonTool DicToJSONString:[chatVoice mj_keyValues]];
    }
}
-(ChatVoice*)getChatVoice{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VOICE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        return [ChatVoice mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取视频
-(void)setChatVideo:(ChatVideo*)chatVideo{
    if(chatVideo!=nil){
        _messageContent=[FlappyJsonTool DicToJSONString:[chatVideo mj_keyValues]];
    }
}
-(ChatVideo*)getChatVideo{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VIDEO){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        return [ChatVideo mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取位置
-(void)setChatLocation:(ChatLocation*)chatLocation{
    if(chatLocation!=nil){
        _messageContent=[FlappyJsonTool DicToJSONString:[chatLocation mj_keyValues]];
    }
}
-(ChatLocation*)getChatLocation{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_LOCATE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        return [ChatLocation mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取文件
-(void)setChatFile:(ChatFile*)chatFile{
    if(chatFile!=nil){
        _messageContent=[FlappyJsonTool DicToJSONString:[chatFile mj_keyValues]];
    }
}
-(ChatFile*)getChatFile{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_FILE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
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
