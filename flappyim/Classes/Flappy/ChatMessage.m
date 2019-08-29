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


//获取系统消息
-(ChatSystem*)getChatSystem{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_SYSTEM){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        if(dic!=nil){
            return [ChatSystem mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//设置聊天文本
-(void)setChatText:(NSString*)chatText{
    //不为空
    if(chatText!=nil&&self.messageType==MSG_TYPE_TEXT){
        _messageContent=[self base64EncodeString:chatText];
    }
}

//获取聊天文本
-(NSString*)getChatText{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_TEXT){
        return [self base64DecodeString:_messageContent];
    }
    return nil;
}

//获取图像
-(ChatImage*)getChatImage{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_IMG){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        if(dic!=nil){
            return [ChatImage mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//获取声音
-(ChatVoice*)getChatVoice{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VOICE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        if(dic!=nil){
            return [ChatVoice mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//获取视频
-(ChatVideo*)getChatVideo{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_VIDEO){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        if(dic!=nil){
            return [ChatVideo mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}

//获取位置
-(ChatLocation*)getChatLocation{
    if(_messageContent!=nil&&self.messageType==MSG_TYPE_LOCATE){
        NSDictionary* dic=[FlappyJsonTool JSONStringToDictionary:_messageContent];
        if(dic!=nil){
            return [ChatLocation mj_objectWithKeyValues:dic];
        }
    }
    return nil;
}


#pragma mark -对一个字符串进行base64编码，并返回
-(NSString *)base64EncodeString:(NSString *)string{
    //1、先转换成二进制数据
    NSData *data =[string dataUsingEncoding:NSUTF8StringEncoding];
    //2、对二进制数据进行base64编码，完成后返回字符串
    return [data base64EncodedStringWithOptions:0];
}
#pragma mark -对一个字符串进行base64解码，并返回
-(NSString *)base64DecodeString:(NSString *)string{
    //注意：该字符串是base64编码后的字符串
    //1、转换为二进制数据（完成了解码的过程）
    NSData *data=[[NSData alloc]initWithBase64EncodedString:string options:0];
    //2、把二进制数据转换成字符串
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

@end
