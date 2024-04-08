//
//  ChatMessage.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import "ChatMessage.h"
#import "MJExtension.h"
#import "FlappyJsonTool.h"

@implementation ChatMessage


//设置|获取消息
-(void)setChatSystem:(ChatSystem*)chatSystem{
    if(chatSystem!=nil){
        _messageContent=[self base64EncodeString:[FlappyJsonTool DicToJSONString:[chatSystem mj_keyValues]]];
    }
}
-(ChatSystem*)getChatSystem{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_SYSTEM){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self base64DecodeString:_messageContent]];
        if(dic!=nil){
            return [ChatSystem mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}


//设置|获取文本
-(void)setChatText:(NSString*)chatText{
    if(chatText!=nil){
        _messageContent=[self base64EncodeString:chatText];
    }
}
-(NSString*)getChatText{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_TEXT){
        return [self base64DecodeString:_messageContent];
    }
    return nil;
}


//设置|获取图像
-(void)setChatImage:(ChatImage*)chatImage{
    if(chatImage!=nil){
        _messageContent=[self base64EncodeString:[FlappyJsonTool DicToJSONString:[chatImage mj_keyValues]]];
    }
}
-(ChatImage*)getChatImage{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_IMG){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self base64DecodeString:_messageContent]];
        if(dic!=nil){
            return [ChatImage mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//设置|获取声音
-(void)setChatVoice:(ChatVoice*)chatVoice{
    if(chatVoice!=nil){
        _messageContent=[self base64EncodeString:[FlappyJsonTool DicToJSONString:[chatVoice mj_keyValues]]];
    }
}
-(ChatVoice*)getChatVoice{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VOICE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self base64DecodeString:_messageContent]];
        if(dic!=nil){
            return [ChatVoice mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//设置|获取视频
-(void)setChatVideo:(ChatVideo*)chatVideo{
    if(chatVideo!=nil){
        _messageContent=[self base64EncodeString:[FlappyJsonTool DicToJSONString:[chatVideo mj_keyValues]]];
    }
}
-(ChatVideo*)getChatVideo{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VIDEO){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self base64DecodeString:_messageContent]];
        if(dic!=nil){
            return [ChatVideo mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//设置|获取位置
-(void)setChatLocation:(ChatLocation*)chatLocation{
    if(chatLocation!=nil){
        _messageContent=[self base64EncodeString:[FlappyJsonTool DicToJSONString:[chatLocation mj_keyValues]]];
    }
}
-(ChatLocation*)getChatLocation{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_LOCATE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self base64DecodeString:_messageContent]];
        if(dic!=nil){
            return [ChatLocation mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}


//设置|获取文件
-(void)setChatFile:(ChatFile*)chatFile{
    if(chatFile!=nil){
        _messageContent=[self base64EncodeString:[FlappyJsonTool DicToJSONString:[chatFile mj_keyValues]]];
    }
}
-(ChatFile*)getChatFile{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_FILE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self base64DecodeString:_messageContent]];
        if(dic!=nil){
            return [ChatFile mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//设置|获取动作
-(void)setChatAction:(ChatAction*)chatAction{
    if(chatAction!=nil){
        _messageContent=[self base64EncodeString:[FlappyJsonTool DicToJSONString:[chatAction mj_keyValues]]];
    }
}
-(ChatAction*)getChatAction{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_ACTION){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:[self base64DecodeString:_messageContent]];
        if(dic!=nil){
            return [ChatAction mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//设置|获取自定义
-(void)setChatCustom:(NSString*)chatText{
    if(chatText!=nil){
        _messageContent=[self base64EncodeString:chatText];
    }
}
-(NSString*)getChatCustom{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_CUSTOM){
        return [self base64DecodeString:_messageContent];
    }
    return nil;
}


#pragma mark -对一个字符串进行base64编码，并返回
-(NSString *)base64EncodeString:(NSString *)string{
    //1、先转换成二进制数据
    NSData *data =[string dataUsingEncoding:NSUTF8StringEncoding];
    //2、对二进制数据进行base64编码，完成后返回字符串
    return [[data base64EncodedStringWithOptions:0] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
}
#pragma mark -对一个字符串进行base64解码，并返回
-(NSString *)base64DecodeString:(NSString *)string{
    //注意：该字符串是base64编码后的字符串
    //1、转换为二进制数据（完成了解码的过程）
    NSData *data=[[NSData alloc]initWithBase64EncodedString:[string stringByReplacingOccurrencesOfString:@"\n" withString:@""] options:0];
    //2、把二进制数据转换成字符串
    return [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
}

@end
