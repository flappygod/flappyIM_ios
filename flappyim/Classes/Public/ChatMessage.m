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


//设置|获取系统消息
-(void)setChatSystem:(ChatSystem*)chatSystem{
    if(chatSystem!=nil){
        NSString* content = [FlappyJsonTool DicToJSONString:[chatSystem mj_keyValues]];
        _messageContent = [self encrypt:content withSecret:nil];
    }
}
-(ChatSystem*)getChatSystem{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_SYSTEM){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self decrypt]];
        return [ChatSystem mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取动作
-(void)setChatAction:(ChatAction*)chatAction{
    if(chatAction!=nil){
        NSString* content = [FlappyJsonTool DicToJSONString:[chatAction mj_keyValues]];
        _messageContent = [self encrypt:content withSecret:nil];
    }
}
-(ChatAction*)getChatAction{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_ACTION){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self decrypt]];
        return [ChatAction mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取文本
-(void)setChatText:(NSString*)chatText{
    if(chatText!=nil){
        _messageContent=[self encrypt:chatText withSecret: [FlappyStringTool RandomString:16]];
    }
}
-(NSString*)getChatText{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_TEXT){
        return [self decrypt];
    }
    return nil;
}


//设置|获取图像
-(void)setChatImage:(ChatImage*)chatImage{
    if(chatImage!=nil){
        NSString* content = [FlappyJsonTool DicToJSONString:[chatImage mj_keyValues]];
        _messageContent=[self encrypt:content withSecret:[FlappyStringTool RandomString:16]];
    }
}
-(ChatImage*)getChatImage{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_IMG){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self decrypt]];
        return [ChatImage mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取声音
-(void)setChatVoice:(ChatVoice*)chatVoice{
    if(chatVoice!=nil){
        NSString* content = [FlappyJsonTool DicToJSONString:[chatVoice mj_keyValues]];
        _messageContent=[self encrypt:content withSecret:[FlappyStringTool RandomString:16]];
    }
}
-(ChatVoice*)getChatVoice{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VOICE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self decrypt]];
        return [ChatVoice mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取视频
-(void)setChatVideo:(ChatVideo*)chatVideo{
    if(chatVideo!=nil){
        NSString* content = [FlappyJsonTool DicToJSONString:[chatVideo mj_keyValues]];
        _messageContent=[self encrypt:content withSecret:[FlappyStringTool RandomString:16]];
    }
}
-(ChatVideo*)getChatVideo{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VIDEO){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self decrypt]];
        return [ChatVideo mj_objectWithKeyValues:dic];
    }
    return nil;
}

//设置|获取位置
-(void)setChatLocation:(ChatLocation*)chatLocation{
    if(chatLocation!=nil){
        NSString* content = [FlappyJsonTool DicToJSONString:[chatLocation mj_keyValues]];
        _messageContent=[self encrypt:content withSecret:[FlappyStringTool RandomString:16]];
    }
}
-(ChatLocation*)getChatLocation{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_LOCATE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self decrypt]];
        return [ChatLocation mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取文件
-(void)setChatFile:(ChatFile*)chatFile{
    if(chatFile!=nil){
        NSString* content = [FlappyJsonTool DicToJSONString:[chatFile mj_keyValues]];
        _messageContent=[self encrypt:content withSecret:[FlappyStringTool RandomString:16]];
    }
}
-(ChatFile*)getChatFile{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_FILE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self decrypt]];
        return [ChatFile mj_objectWithKeyValues:dic];
    }
    return nil;
}


//设置|获取自定义
-(void)setChatCustom:(NSString*)chatText{
    if(chatText!=nil){
        _messageContent=[self encrypt:chatText withSecret:[FlappyStringTool RandomString:16]];
    }
}
-(NSString*)getChatCustom{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_CUSTOM){
        return [self decrypt];
    }
    return nil;
}

//转换map
-(NSMutableDictionary *)toMap {
    NSMutableDictionary* dic = [self mj_keyValues];
    switch (_messageType) {
        case MSG_TYPE_SYSTEM:
            dic[@"messageData"] = [FlappyJsonTool DicToJSONString: [[self getChatSystem] mj_keyValues]];
            break;
        case MSG_TYPE_TEXT:
            dic[@"messageData"] = [self getChatText];
            break;
        case MSG_TYPE_IMG:
            dic[@"messageData"] = [FlappyJsonTool DicToJSONString: [[self getChatImage] mj_keyValues]];
            break;
        case MSG_TYPE_VOICE:
            dic[@"messageData"] = [FlappyJsonTool DicToJSONString: [[self getChatVoice] mj_keyValues]];
            break;
        case MSG_TYPE_LOCATE:
            dic[@"messageData"] = [FlappyJsonTool DicToJSONString: [[self getChatLocation] mj_keyValues]];
            break;
        case MSG_TYPE_VIDEO:
            dic[@"messageData"] = [FlappyJsonTool DicToJSONString: [[self getChatVideo] mj_keyValues]];
            break;
        case MSG_TYPE_FILE:
            dic[@"messageData"] = [FlappyJsonTool DicToJSONString: [[self getChatFile] mj_keyValues]];
            break;
        case MSG_TYPE_CUSTOM:
            dic[@"messageData"] =[self getChatCustom];
            break;
        case MSG_TYPE_ACTION:
            dic[@"messageData"] = [FlappyJsonTool DicToJSONString: [[self getChatAction] mj_keyValues]];
            break;
        default:
            break;
    }
    return dic;
}



//加密
-(NSString*)encrypt:(NSString*) data withSecret:(NSString*)secret{
    _messageSecretSend = secret;
    if(_messageSecretSend==nil||_messageSecretSend.length==0){
        return [self base64Encode:data];
    }else{
        return [Aes128 AES128Encrypt:data withKey:secret];
    }
}

//解密
-(NSString*)decrypt{
    NSString* secret = _messageSecretSend;
    if(secret==nil||secret.length==0){
        return [self base64Decode:_messageContent];
    }else{
        return  [Aes128 AES128Decrypt:_messageContent withKey:secret];
    }
}

//Base64加密
-(NSString *)base64Encode:(NSString *)string{
    //1、先转换成二进制数据
    NSData *data =[string dataUsingEncoding:NSUTF8StringEncoding];
    //2、对二进制数据进行base64编码，完成后返回字符串
    return [[data base64EncodedStringWithOptions:0] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
}

//Base64解码
-(NSString *)base64Decode:(NSString *)string{
    //注意：该字符串是base64编码后的字符串
    //1、转换为二进制数据（完成了解码的过程）
    NSData *data=[[NSData alloc]initWithBase64EncodedString:[string stringByReplacingOccurrencesOfString:@"\n" withString:@""] options:0];
    //2、把二进制数据转换成字符串
    return [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
}




@end
