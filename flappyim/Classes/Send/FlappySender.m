//
//  FlappySender.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import "FlappySender.h"
#import "FlappyBaseSession.h"
#import "FlappyUploadTool.h"
#import "MJExtension.h"
#import "FlappyJsonTool.h"
#import "FlappyImageTool.h"
#import "FlappyDataBase.h"
#import "FlappyData.h"
#import "FlappyApiConfig.h"
#import "FlappyStringTool.h"
#import "FlappyApiRequest.h"
#import "FlappyVideoInfo.h"
#import <AVFoundation/AVAsset.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>


@interface FlappySender()


//成功
@property(nonatomic,strong) NSMutableDictionary* successCallbacks;

//失败
@property(nonatomic,strong) NSMutableDictionary* failureCallbacks;

//请求
@property(nonatomic,strong) NSMutableArray* reqArray;

@end


@implementation FlappySender


//使用单例模式
+ (instancetype)shareInstance {
    static FlappySender *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        _sharedSingleton = [[super allocWithZone:NULL] init];
        //初始化
        _sharedSingleton.successCallbacks=[[NSMutableDictionary alloc]init];
        _sharedSingleton.failureCallbacks=[[NSMutableDictionary alloc]init];
        _sharedSingleton.sendingMessages=[[NSMutableDictionary alloc]init];
        _sharedSingleton.reqArray=[[NSMutableArray alloc]init];
    });
    return _sharedSingleton;
}


// 防止外部调用alloc或者new
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [FlappySender shareInstance];
}

// 防止外部调用copy
- (id)copyWithZone:(nullable NSZone *)zone {
    return [FlappySender shareInstance];
}

// 防止外部调用mutableCopy
- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [FlappySender shareInstance];
}


//发送音频文件
-(void)uploadVoiceAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure{
    
    //已经上传了
    if(![FlappyStringTool isStringEmpty:[chatMsg getChatImage].path]){
        
        [self sendMessage:chatMsg
               andSuccess:success
               andFailure:failure];
        return;
    }
    
    //语音信息
    ChatVoice* chatVoice=[chatMsg getChatVoice];
    
    @try {
        //根据地址来
        NSURL* url;
        //如果以file开头
        if([chatVoice.sendPath hasPrefix:@"file"]){
            //直接
            url=[NSURL URLWithString:chatVoice.sendPath];
        }else{
            //否则不用了
            url=[NSURL URLWithString:[NSString stringWithFormat:@"file://%@",chatVoice.sendPath]];
        }
        //地址
        AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:url
                                                     options:nil];
        //获取长度
        if(audioAsset==nil){
            [self updateMsgFailure:chatMsg];
            failure(chatMsg,[NSError errorWithDomain:@"音频读取失败" code:0 userInfo:nil],
                    RESULT_PARSE_ERROR);
            return;
        }
        
        //长度
        CMTime audioDuration = audioAsset.duration;
        //seconds
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        //长度
        chatVoice.seconds=[NSString stringWithFormat:@"%ld",(long)audioDurationSeconds*1000];
    } @catch (NSException *exception) {
        [self updateMsgFailure:chatMsg];
        failure(chatMsg,[NSError errorWithDomain:@"音频读取失败" code:0 userInfo:nil],
                RESULT_PARSE_ERROR);
        return;
    }
    
    //更新消息
    [chatMsg setChatVoice:chatVoice];
    
    //插入消息
    [self insertMessage:chatMsg];
    
    //开始请求
    FlappyUploadTool* req=[[FlappyUploadTool alloc]init];
    
    //自己
    __weak typeof(self) safeSelf=self;
    __weak typeof (req) safeReq=req;
    
    //成功
    req.successBlock=^(id data){
        //字典
        NSDictionary* dic=data;
        
        NSString* resultCode=dic[@"code"];
        //成功
        if(resultCode.integerValue==RESULT_SUCCESS){
            
            NSArray* dataList=dic[@"data"];
            //地址
            NSString* path=dataList.count > 0? dataList[0]:@"";
            //地址
            chatVoice.path=path;
            //设置
            [chatMsg setChatVoice:chatVoice];
            //上传完成发送消息
            [safeSelf sendMessage:chatMsg
                       andSuccess:success
                       andFailure:failure];
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }else{
            [safeSelf updateMsgFailure:chatMsg];
            //上传失败了
            failure(chatMsg,[NSError errorWithDomain:@"文件上传失败" code:0 userInfo:nil],
                    RESULT_NETERROR);
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }
    };
    
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf updateMsgFailure:chatMsg];
        //上传失败了
        failure(chatMsg,[NSError errorWithDomain:error.reason code:0 userInfo:nil],
                RESULT_NETERROR);
        //移除请求释放资源
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    //上传文件
    FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
    uploadReq.path=chatVoice.sendPath;
    uploadReq.name=@"file";
    uploadReq.type=@"voice";
    
    //上传文件
    [req uploadFileBaseModel:[FlappyApiConfig shareInstance].URL_fileUpload
                    andModel:uploadReq];
    
    //添加进入请求列表，方式请求被回收
    [self.reqArray addObject:req];
    
}


//上传图片并发送
-(void)uploadImageAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure{
    
    //已经上传了
    if(![FlappyStringTool isStringEmpty:[chatMsg getChatImage].path]){
        
        [self sendMessage:chatMsg
               andSuccess:success
               andFailure:failure];
        return;
    }
    
    //图片信息
    ChatImage* chatImg=[chatMsg getChatImage];
    @try {
        //先拿数据看看那
        CGSize size=[FlappyImageTool getImageSizeWithPath:chatImg.sendPath];
        chatImg.width=[NSString stringWithFormat:@"%d",(int)size.width];
        chatImg.height=[NSString stringWithFormat:@"%d",(int)size.height];
        //没有拿到，继续其他方式拿
        if(chatImg.width==0&&chatImg.height==0){
            NSString* trueUrl=chatImg.sendPath;
            if([trueUrl hasPrefix:@"file://"]){
                trueUrl = [trueUrl substringWithRange:NSMakeRange(7, trueUrl.length-7)];
            }
            //获取图片
            UIImage* image=[[UIImage alloc]initWithContentsOfFile:trueUrl];
            //不为空
            if(image==nil){
                [self updateMsgFailure:chatMsg];
                failure(chatMsg,[NSError errorWithDomain:@"图片读取失败" code:0 userInfo:nil],
                        RESULT_PARSE_ERROR);
                return;
            }
            //保存宽度
            chatImg.width=[NSString stringWithFormat:@"%ld",(long)image.size.width];
            //保存高度
            chatImg.height=[NSString stringWithFormat:@"%ld",(long)image.size.height];
        }
    } @catch (NSException *exception) {
        //失败了
        [self updateMsgFailure:chatMsg];
        //图片读取失败
        failure(chatMsg,[NSError errorWithDomain:@"图片读取失败" code:0 userInfo:nil],
                RESULT_PARSE_ERROR);
        //返回
        return;
    }
    //更新消息
    [chatMsg setChatImage:chatImg];
    //插入消息
    [self insertMessage:chatMsg];
    //开始请求
    FlappyUploadTool* req=[[FlappyUploadTool alloc]init];
    //自己
    __weak typeof(self) safeSelf=self;
    //用于引用
    __weak typeof (req) safeReq=req;
    //成功
    req.successBlock=^(id data){
        //字典
        NSDictionary* dic=data;
        //Code
        NSString* resultCode=dic[@"code"];
        //成功
        if(resultCode.integerValue==RESULT_SUCCESS && [dic[@"data"] isKindOfClass:NSArray.class]){
            NSArray* dataList=dic[@"data"];
            //地址
            NSString* path=dataList.count > 0? dataList[0]:@"";
            //地址赋值
            chatImg.path=path;
            //设置
            [chatMsg setChatImage:chatImg];
            //上传完成发送消息
            [safeSelf sendMessage:chatMsg
                       andSuccess:success
                       andFailure:failure];
            [safeSelf.reqArray removeObject:safeReq];
        }else{
            [safeSelf updateMsgFailure:chatMsg];
            //上传失败了
            failure(chatMsg,[NSError errorWithDomain:@"文件上传失败" code:0 userInfo:nil],
                    RESULT_NETERROR);
            [safeSelf.reqArray removeObject:safeReq];
        }
        
    };
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf updateMsgFailure:chatMsg];
        //上传失败了
        failure(chatMsg,[NSError errorWithDomain:error.description code:0 userInfo:nil],
                RESULT_NETERROR);
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    
    //上传
    FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
    uploadReq.path=chatImg.sendPath;
    uploadReq.name=@"file";
    uploadReq.type=@"image";
    [req uploadFileBaseModel:[FlappyApiConfig shareInstance].URL_fileUpload
                    andModel:uploadReq];
    
    
    //添加进入请求列表，方式请求被回收
    [self.reqArray addObject:req];
    
}

//发送音频文件
-(void)uploadVideoAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySendSuccess)success
               andFailure:(FlappySendFailure)failure{
    //已经上传了
    if(![FlappyStringTool isStringEmpty:[chatMsg getChatImage].path]){
        
        [self sendMessage:chatMsg
               andSuccess:success
               andFailure:failure];
        return;
    }
    
    //视频信息
    ChatVideo* chatVideo=[chatMsg getChatVideo];
    
    //开始请求
    FlappyUploadTool* req=[[FlappyUploadTool alloc]init];
    
    //自己
    __weak typeof(self) safeSelf=self;
    __weak typeof (req) safeReq=req;
    
    //成功
    req.successBlock=^(id data){
        //字典
        NSDictionary* dic=data;
        
        NSString* resultCode=dic[@"code"];
        //成功
        if(resultCode.integerValue==RESULT_SUCCESS){
            //地址
            chatVideo.path=dic[@"data"][@"filePath"];
            //封面
            chatVideo.coverPath=dic[@"data"][@"overFilePath"];
            //设置
            [chatMsg setChatVideo:chatVideo];
            //上传完成发送消息
            [safeSelf sendMessage:chatMsg
                       andSuccess:success
                       andFailure:failure];
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }else{
            [safeSelf updateMsgFailure:chatMsg];
            //上传失败了
            failure(chatMsg,[NSError errorWithDomain:@"图片上传失败" code:0 userInfo:nil],
                    RESULT_NETERROR);
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }
    };
    
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf updateMsgFailure:chatMsg];
        //上传失败了
        failure(chatMsg,[NSError errorWithDomain:error.reason code:0 userInfo:nil],
                RESULT_NETERROR);
        //移除请求释放资源
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    NSMutableArray* uplaods=[[NSMutableArray alloc]init];
    
    
    @try {
        //根据地址来
        NSURL* url;
        
        //如果以file开头
        if([chatVideo.sendPath hasPrefix:@"file"]){
            //直接
            url=[NSURL URLWithString:chatVideo.sendPath];
        }else{
            //否则不用了
            url=[NSURL URLWithString:[NSString stringWithFormat:@"file://%@",chatVideo.sendPath]];
        }
        //获取视频信息
        FlappyVideoInfo* info=[self videoInfoForUrl:url
                                               size:CGSizeMake(512, 512)];
        //返回数据
        if(info==nil||info.overPath==nil||info.duration==nil||info.vwidth==nil||info.vheight==nil){
            @throw [[NSException alloc]initWithName:@"视频解析失败"
                                             reason:@"视频解析失败"
                                           userInfo:nil];
        }
        chatVideo.width=info.vwidth;
        chatVideo.height=info.vheight;
        chatVideo.duration=info.duration;
        chatVideo.coverSendPath = info.overPath;
        [chatMsg setChatVideo:chatVideo];
        
        //上传文件
        FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
        uploadReq.path=info.overPath;
        uploadReq.name=@"cover";
        uploadReq.type=@"image";
        [uplaods addObject:uploadReq];
        
    } @catch (NSException *exception) {
        [self updateMsgFailure:chatMsg];
        failure(chatMsg,[NSError errorWithDomain:@"视频读取失败" code:0 userInfo:nil],
                RESULT_PARSE_ERROR);
        return;
    }
    
    //消息
    [self insertMessage:chatMsg];
    
    //上传文件
    FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
    uploadReq.path=chatVideo.sendPath;
    uploadReq.name=@"video";
    uploadReq.type=@"video";
    //上传
    [uplaods addObject:uploadReq];
    
    [req uploadFilesBaseModel:[FlappyApiConfig shareInstance].URL_videoUpload
                    andModels:uplaods];
    //添加进入请求列表，方式请求被回收
    [self.reqArray addObject:req];
}


//上传文件并发送
-(void)uploadFileAndSend:(ChatMessage*)chatMsg
              andSuccess:(FlappySendSuccess)success
              andFailure:(FlappySendFailure)failure{
    
    //已经上传了
    if(![FlappyStringTool isStringEmpty:[chatMsg getChatFile].path]){
        
        [self sendMessage:chatMsg
               andSuccess:success
               andFailure:failure];
        return;
    }
    
    //图片信息
    ChatFile* chatFile=[chatMsg getChatFile];
    
    //文件大小
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:chatFile.sendPath]){
        chatFile.fileSize = [NSString stringWithFormat:@"%llu",[[manager attributesOfItemAtPath:chatFile.sendPath error:nil] fileSize]];
    }
    [chatMsg setChatFile:chatFile];
    
    //插入消息
    [self insertMessage:chatMsg];
    
    //开始请求
    FlappyUploadTool* req=[[FlappyUploadTool alloc]init];
    
    //自己
    __weak typeof(self) safeSelf=self;
    
    //用于引用
    __weak typeof (req) safeReq=req;
    
    //成功
    req.successBlock=^(id data){
        
        //字典
        NSDictionary* dic=data;
        
        //code
        NSString* resultCode=dic[@"code"];
        
        //成功
        if(resultCode.integerValue==RESULT_SUCCESS && [dic[@"data"] isKindOfClass:NSArray.class]){
            NSArray* dataList=dic[@"data"];
            //地址
            NSString* path=dataList.count > 0? dataList[0]:@"";
            //地址赋值
            chatFile.path=path;
            //设置
            [chatMsg setChatFile:chatFile];
            //上传完成发送消息
            [safeSelf sendMessage:chatMsg
                       andSuccess:success
                       andFailure:failure];
            [safeSelf.reqArray removeObject:safeReq];
        }else{
            [safeSelf updateMsgFailure:chatMsg];
            //上传失败了
            failure(chatMsg,[NSError errorWithDomain:@"文件上传失败" code:0 userInfo:nil],
                    RESULT_NETERROR);
            [safeSelf.reqArray removeObject:safeReq];
        }
        
    };
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf updateMsgFailure:chatMsg];
        failure(chatMsg,[NSError errorWithDomain:error.description code:0 userInfo:nil],
                RESULT_NETERROR);
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    //上传
    FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
    uploadReq.path=chatFile.sendPath;
    uploadReq.name=@"file";
    uploadReq.type=@"file";
    [req uploadFileBaseModel:[FlappyApiConfig shareInstance].URL_fileUpload
                    andModel:uploadReq];
    
    
    //添加进入请求列表，方式请求被回收
    [self.reqArray addObject:req];
}

//插入数据库
-(void)insertMessage:(ChatMessage*)msg{
    //我们先姑且认为它是最后一条
    ChatUser* user=[[FlappyData shareInstance]getUser];
    
    //最近的一条消息
    msg.messageSendState=SEND_STATE_SENDING;
    
    //设置message stamp
    msg.messageStamp = (NSInteger)([NSDate date].timeIntervalSince1970*1000);
    
    //添加一个
    NSInteger value=(user.latest!=nil? user.latest.integerValue:0)+1;
    
    //设置offset，仅用于排序，最终以服务器端返回为准
    msg.messageTableOffset=value;
    
    //插入消息数据
    [[FlappyDataBase shareInstance] insertMessage:msg];
    
    //发送插入消息通知
    [self notifyMessageSendInsert:msg];
}

//发送失败
-(void)updateMsgFailure:(ChatMessage*)msg{
    //更新失败消息
    msg.messageSendState=SEND_STATE_FAILURE;
    [[FlappyDataBase shareInstance] updateMessage:msg];
    
    //发送失败通知
    [self notifyMessageFailure:msg];
}


//发送失败
-(void)updateMsgDelete:(ChatMessage*)msg{
    //更新失败消息
    msg.isDelete=1;
    
    //更新消息
    [[FlappyDataBase shareInstance] updateMessage:msg];
    
    //发送失败通知
    [self notifyMessageDelete:msg];
}


//发送消息
-(void)sendMessage:(ChatMessage*)chatMsg
        andSuccess:(FlappySendSuccess)success
        andFailure:(FlappySendFailure)failure{
    
    //消息
    [self insertMessage:chatMsg];
    
    //之前的回调错误信息
    ChatMessage* former=[self.sendingMessages objectForKey:chatMsg.messageId];
    if(former!=nil){
        [self handleSendFailureCallback:chatMsg];
    }
    
    //消息ID保存
    [self.successCallbacks setObject:success forKey:chatMsg.messageId];
    //消息ID保存
    [self.failureCallbacks setObject:failure forKey:chatMsg.messageId];
    //消息ID保存
    [self.sendingMessages setObject:chatMsg forKey:chatMsg.messageId];
    
    //获取socket,如果当前的socket是正常的状态直接发送消息
    FlappySocket* socket=self.flappySocket;
    if(socket!=nil && socket.isActive){
        [socket sendMessage:chatMsg];
    }
}

//成功
-(void)handleSendSuccessCallback:(ChatMessage*)chatMsg{
    if(chatMsg==nil){
        return;
    }
    //在主线程之中执行
    dispatch_async(dispatch_get_main_queue(), ^{
        FlappySendSuccess success=[self.successCallbacks objectForKey:chatMsg.messageId];
        if(success!=nil){
            success(chatMsg);
            [self.successCallbacks removeObjectForKey:chatMsg.messageId];
            [self.failureCallbacks removeObjectForKey:chatMsg.messageId];
            [self.sendingMessages removeObjectForKey:chatMsg.messageId];
        }
    });
    
}

//失败
-(void)handleSendFailureCallback:(ChatMessage*)message{
    if(message==nil){
        return;
    }
    //消息发送失败
    [self updateMsgFailure:message];
    //在主线程之中执行
    dispatch_async(dispatch_get_main_queue(), ^{
        FlappySendFailure failure=[self.failureCallbacks objectForKey:message.messageId];
        if(failure!=nil && message!=nil){
            failure(message,[NSError errorWithDomain:@"连接已经断开" code:0 userInfo:nil],RESULT_NETERROR);
            [self.successCallbacks removeObjectForKey:message.messageId];
            [self.failureCallbacks removeObjectForKey:message.messageId];
            [self.sendingMessages removeObjectForKey:message.messageId];
        }
    });
}

//全部失败
-(void)handleSendFailureAllCallback{
    if(self.sendingMessages==nil||self.sendingMessages.count==0){
        return;
    }
    NSMutableDictionary* dic=self.sendingMessages;
    NSArray* array=dic.allKeys;
    for(int s=0;s<array.count;s++){
        [self handleSendFailureCallback:[self.sendingMessages objectForKey:[array objectAtIndex:s]]];
    }
}


//消息已读回执和删除回执,对方的阅读消息存在的时候才会执行
-(void)handleMessageAction:(ChatMessage*)message{
    if(message==nil){
        return;
    }
    if(message.messageType == MSG_TYPE_ACTION && message.messageReadState == 0){
        [[FlappyDataBase shareInstance] handleActionMessageUpdate:message];
        ChatAction* chatAction = [message getChatAction];
        switch(chatAction.actionType){
                //会话阅读
            case ACTION_TYPE_READ_SESSION:{
                ChatUser* user=[[FlappyData shareInstance] getUser];
                //自己读的
                if([user.userId isEqualToString:chatAction.actionIds[0]]){
                    [self notifyMessageSelfRead:chatAction.actionIds[1]
                                    andReaderId:chatAction.actionIds[0]
                               andTableSequecne:chatAction.actionIds[2]];
                }
                //其他人读的
                else{
                    [self notifyMessageOtherRead:chatAction.actionIds[1]
                                     andReaderId:chatAction.actionIds[0]
                                andTableSequecne:chatAction.actionIds[2]];
                }
                break;
            }
                //会话更新
            case ACTION_TYPE_MUTE_SESSION:
            case ACTION_TYPE_PINNED_SESSION:{
                SessionData* session = [[FlappyDataBase shareInstance] getUserSessionByID:chatAction.actionIds[1]];
                [self notifySession:session];
                break;
            }
                //消息被删除
            case ACTION_TYPE_DELETE_MSG:
            case ACTION_TYPE_RECALL_MSG:{
                ChatMessage* message = [[FlappyDataBase shareInstance] getMessageById:chatAction.actionIds[2]];
                [self notifyMessageDelete:message];
                break;
            }
                
        }
    }
}


//通知有新的消息
-(void)notifyMessageOtherRead:(NSString*)sessionId
                  andReaderId:(NSString*)readerId
             andTableSequecne:(NSString*)tableOffset{
    if(sessionId==nil ||readerId==nil|| tableOffset==nil){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            //当前会话或者全局
            if([str isEqualToString:GlobalKey] || [str isEqualToString:sessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onOtherRead:sessionId
                              andReaderId:readerId
                               andSequece:tableOffset];
                }
            }
            
        }
    });
}

//通知有新的消息
-(void)notifyMessageSelfRead:(NSString*)sessionId
                 andReaderId:(NSString*)readerId
            andTableSequecne:(NSString*)tableOffset{
    if(sessionId==nil ||readerId==nil|| tableOffset==nil){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            //当前会话或者全局
            if([str isEqualToString:GlobalKey] || [str isEqualToString:sessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onSelfRead:sessionId
                             andReaderId:readerId
                              andSequece:tableOffset];
                }
            }
            
        }
    });
}

//通知消息发送
-(void)notifyMessageSendInsert:(ChatMessage*)msg{
    if(msg==nil || msg.messageType == MSG_TYPE_ACTION){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            if([str isEqualToString:GlobalKey] || [str isEqualToString:msg.messageSessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onSend:msg];
                }
            }
        }
    });
}


//通知消息接收
-(void)notifyMessageReceiveList:(NSArray*)msgList{
    if (msgList == nil || msgList.count == 0) {
        return;
    }
    
    //使用谓词过滤数组
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(ChatMessage *msg, NSDictionary *bindings) {
        return msg.messageType != MSG_TYPE_ACTION;
    }];
    NSArray *chatMessageList = [msgList filteredArrayUsingPredicate:predicate];
    if (chatMessageList.count == 0) {
        return;
    }
    
    //通知列表到了
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *messageListeners = [FlappyIM shareInstance].messageListeners;
        NSArray *keyArray = messageListeners.allKeys;
        for (NSString *key in keyArray) {
            NSMutableArray *listeners = messageListeners[key];
            if(listeners ==nil){
                continue;
            }
            if ([key isEqualToString:GlobalKey]) {
                for (FlappyMessageListener *listener in listeners) {
                    [listener onReceiveList:chatMessageList];
                }
            } else {
                NSMutableArray *sessionMsgArray = [NSMutableArray array];
                for (ChatMessage *msg in chatMessageList) {
                    if ([key isEqualToString:msg.messageSessionId]) {
                        [sessionMsgArray addObject:msg];
                    }
                }
                if (sessionMsgArray.count > 0) {
                    for (FlappyMessageListener *listener in listeners) {
                        [listener onReceiveList:sessionMsgArray];
                    }
                }
            }
        }
    });
}


//通知消息接收
-(void)notifyMessageReceive:(ChatMessage*)msg{
    if(msg==nil || msg.messageType == MSG_TYPE_ACTION){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            if([str isEqualToString:GlobalKey] || [str isEqualToString:msg.messageSessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onReceive:msg];
                }
            }
        }
    });
}


//通知消息失败
-(void)notifyMessageFailure:(ChatMessage*)msg{
    if(msg==nil || msg.messageType == MSG_TYPE_ACTION){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            if([str isEqualToString:GlobalKey] || [str isEqualToString:msg.messageSessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onFailure:msg];
                }
            }
        }
    });
}

//通知有新的消息
-(void)notifyMessageDelete:(ChatMessage*)msg{
    if(msg==nil || msg.messageType == MSG_TYPE_ACTION){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].messageListeners.allKeys;
        for(int s=0;s<array.count;s++){
            NSString* str=[array objectAtIndex:s];
            if([str isEqualToString:GlobalKey] || [str isEqualToString:msg.messageSessionId]){
                NSMutableArray* listeners=[[FlappyIM shareInstance].messageListeners objectForKey:str];
                for(int w=0;w<listeners.count;w++){
                    FlappyMessageListener* listener=[listeners objectAtIndex:w];
                    [listener onDelete:msg];
                }
            }
        }
    });
}

//会话
-(void)notifySession:(SessionData*)session{
    if(session==nil){
        return;
    }
    //在主线程之中执行
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray* array=[FlappyIM shareInstance].sessionListeners;
        for(int s=0;s<array.count;s++){
            SessionListener listener=[array objectAtIndex:s];
            listener(session);
        }
    });
}

//会话
-(void)notifySessionList:(NSArray*)sessionList{
    if(sessionList==nil || sessionList.count==0){
        return;
    }
    for(int s=0;s<sessionList.count;s++){
        [self notifySession:[sessionList objectAtIndex:s]];
    }
}


//获取视频第一帧
#pragma mark ---- 获取图片第一帧

//生成一个临时的图片地址用于保存封面图片
-(NSString*)generateSaveImagePath{
    /*
     项目中的应用场景是，本地视频在显示的时候需要显示缩略图，通过AVURLAsset等部分代码获取之后，将图片保存到本地做一下缓存，下次搜索是否有图片，有就直接加载
     */
    //获取路径也是一样的
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    /*
     拼接最后完整的路径，这块做的时候遇到个坑，记录如下
     拿到上述路径之后，下面部分代码在于将最后文件的路径补全，首先要加上‘/'这个分隔符,然后后面的是文件的名字,最后的效果如下,
     /var/mobile/Containers/Data/Application/400BC47D-FBC5-412F-8F55-163E5FBB8264/Documents/thumImage2017_0818_101305_0028_F.jpg
     -----之前这个没有加'/’这个分隔符，导致怎么保存之后都拿不到图片
     */
    NSString* str=[NSString stringWithFormat:@"%ld",(long)[NSDate date].timeIntervalSince1970*1000];
    //拼接地址
    NSString *imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg",str]];
    //返回地址
    return imagePath;
}

//获取网络url的video信息
- (FlappyVideoInfo*)videoInfoForUrl:(NSURL *)url size:(CGSize)size
{
    FlappyVideoInfo* info=[[FlappyVideoInfo alloc] init];
    // 获取视频第一帧
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    //获取
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    //获取到文件的时长
    CMTime audioDuration = urlAsset.duration;
    //seconds
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    //长度
    info.duration=[NSString stringWithFormat:@"%ld",(long)audioDurationSeconds*1000];
    //获取到图片
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(size.width, size.height);
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, 10) actualTime:NULL error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:img];
    info.vwidth=[NSString stringWithFormat:@"%ld",(long)videoImage.size.width];
    info.vheight=[NSString stringWithFormat:@"%ld",(long)videoImage.size.height];
    CGImageRelease(img);
    NSString* savePath=[self generateSaveImagePath];
    [self saveToDocument:videoImage withFilePath:savePath];
    info.overPath=savePath;
    return info;
}

//将选取的图片保存到目录文件夹下
-(BOOL)saveToDocument:(UIImage *) image withFilePath:(NSString *) filePath
{
    if ((image == nil) || (filePath == nil) || [filePath isEqualToString:@""]) {
        return NO;
    }
    @try {
        NSData *imageData = nil;
        //获取文件扩展名
        NSString *extention = [filePath pathExtension];
        if ([extention isEqualToString:@"png"]) {
            //返回PNG格式的图片数据
            imageData = UIImagePNGRepresentation(image);
        }else{
            //返回JPG格式的图片数据，第二个参数为压缩质量：0:best 1:lost
            imageData = UIImageJPEGRepresentation(image, 0);
        }
        if (imageData == nil || [imageData length] <= 0) {
            return NO;
        }
        //将图片写入指定路径
        [imageData writeToFile:filePath atomically:YES];
        return  YES;
    }
    @catch (NSException *exception) {
        NSLog(@"保存图片失败");
    }
    return NO;
}

@end
