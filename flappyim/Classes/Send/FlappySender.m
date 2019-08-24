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
#import <AVFoundation/AVAsset.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>


@interface FlappySender()


//成功
@property(nonatomic,strong) NSMutableDictionary<FlappySendSuccess>* successCallbacks;

//失败
@property(nonatomic,strong) NSMutableDictionary<FlappySendFailure>* failureCallbacks;

//消息
@property(nonatomic,strong) NSMutableDictionary* successMsgs;

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
        _sharedSingleton.successMsgs=[[NSMutableDictionary alloc]init];
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
    
    //消息
    [self msgInsert:chatMsg];
    
    //图片信息
    ChatVoice* chatVoice=[ChatVoice mj_objectWithKeyValues:[FlappyJsonTool JSONStringToDictionary:chatMsg.messageContent]];
    
    //开始请求
    FlappyUploadTool* req=[[FlappyUploadTool alloc]init];
    
    //自己
    __weak typeof(self) safeSelf=self;
    __weak typeof (req) safeReq=req;
    
    //成功
    req.successBlock=^(id data){
        //字典
        NSDictionary* dic=data;
        
        NSString* resultCode=dic[@"resultCode"];
        //成功
        if(resultCode.integerValue==RESULT_SUCCESS){
            //地址赋值
            chatVoice.path=dic[@"resultData"];
            //设置
            chatMsg.messageContent=[FlappyJsonTool DicToJSONString:[chatVoice mj_keyValues]];
            //上传完成发送消息
            [safeSelf sendMessage:chatMsg
                       andSuccess:success
                       andFailure:failure];
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }else{
            [safeSelf msgFailure:chatMsg];
            //上传失败了
            failure([NSError errorWithDomain:@"图片上传失败" code:0 userInfo:nil],
                    RESULT_NETERROR);
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }
    };
    
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf msgFailure:chatMsg];
        //上传失败了
        failure([NSError errorWithDomain:error.reason code:0 userInfo:nil],
                RESULT_NETERROR);
        //移除请求释放资源
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    
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
            [self msgFailure:chatMsg];
            failure([NSError errorWithDomain:@"音频读取失败" code:0 userInfo:nil],
                    RESULT_FILEERR);
            return;
        }
        
        //长度
        CMTime audioDuration = audioAsset.duration;
        //seconds
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        //长度
        chatVoice.seconds=[NSString stringWithFormat:@"%ld",(long)audioDurationSeconds*1000];
    } @catch (NSException *exception) {
        [self msgFailure:chatMsg];
        failure([NSError errorWithDomain:@"音频读取失败" code:0 userInfo:nil],
                RESULT_FILEERR);
        return;
    } @finally {
        
    }
    
    //上传文件
    FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
    uploadReq.path=chatVoice.sendPath;
    uploadReq.name=@"file";
    uploadReq.type=@"video";
    
    [req uploadImageAndMovieBaseModel:[FlappyApiConfig shareInstance].URL_fileUpload
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
    
    //消息
    [self msgInsert:chatMsg];
    
    //图片信息
    ChatImage* chatImg=[ChatImage mj_objectWithKeyValues:[FlappyJsonTool JSONStringToDictionary:chatMsg.messageContent]];
    
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
        
        NSString* resultCode=dic[@"resultCode"];
        //成功
        if(resultCode.integerValue==RESULT_SUCCESS){
            //地址
            NSString* imgPath=dic[@"resultData"];
            //地址赋值
            chatImg.path=imgPath;
            //设置
            chatMsg.messageContent=[FlappyJsonTool DicToJSONString:[chatImg mj_keyValues]];
            //上传完成发送消息
            [safeSelf sendMessage:chatMsg
                       andSuccess:success
                       andFailure:failure];
            [safeSelf.reqArray removeObject:safeReq];
        }else{
            [safeSelf msgFailure:chatMsg];
            //上传失败了
            failure(chatMsg,[NSError errorWithDomain:@"文件上传失败" code:0 userInfo:nil],
                    RESULT_NETERROR);
            [safeSelf.reqArray removeObject:safeReq];
        }
        
    };
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf msgFailure:chatMsg];
        //上传失败了
        failure([NSError errorWithDomain:error.description code:0 userInfo:nil],
                RESULT_NETERROR);
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    @try {
        //获取图片
        UIImage* image=[[UIImage alloc]initWithContentsOfFile:chatImg.sendPath];
        //不为空
        if(image==nil){
            [self msgFailure:chatMsg];
            failure([NSError errorWithDomain:@"图片读取失败" code:0 userInfo:nil],
                    RESULT_FILEERR);
            return;
        }
        //保存宽度
        chatImg.width=[NSString stringWithFormat:@"%ld",(long)image.size.width];
        //保存高度
        chatImg.height=[NSString stringWithFormat:@"%ld",(long)image.size.height];
    } @catch (NSException *exception) {
        //失败了
        [self msgFailure:chatMsg];
        //图片读取失败
        failure(chatMsg,[NSError errorWithDomain:@"图片读取失败" code:0 userInfo:nil],
                RESULT_FILEERR);
        //返回
        return;
    } @finally {
        
    }
    
    //上传
    FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
    uploadReq.path=chatImg.sendPath;
    uploadReq.name=@"file";
    uploadReq.type=@"image";
    [req uploadImageAndMovieBaseModel:[FlappyApiConfig shareInstance].URL_fileUpload
                             andModel:uploadReq];
    
    
    //添加进入请求列表，方式请求被回收
    [self.reqArray addObject:req];
    
}


//发送消息
-(void)sendMessage:(ChatMessage*)chatMsg
        andSuccess:(FlappySendSuccess)success
        andFailure:(FlappySendFailure)failure{
    
    //消息
    [self msgInsert:chatMsg];
    
    //获取socket
    GCDAsyncSocket* socket=self.socket;
    
    //连接已经断开了
    if(socket==nil){
        [self msgFailure:chatMsg];
        failure(chatMsg,[NSError errorWithDomain:@"连接已断开" code:0 userInfo:nil],RESULT_NETERROR);
        return;
    }
    
    //连接到服务器开始请求登录
    FlappyRequest* request=[[FlappyRequest alloc]init];
    //登录请求
    request.type=REQ_MSG;
    //登录信息
    request.msg=[FlappyBaseSession changeToMessage:chatMsg];
    
    //请求数据，已经GPBComputeRawVarint32SizeForInteger
    NSData* reqData=[request delimitedData];
    //当前的时间戳
    NSInteger  dateTime=(NSInteger)([[NSDate date] timeIntervalSince1970]*1000);
    //设置
    NSString* dateTimeStr=[NSString stringWithFormat:@"%ld",(long)dateTime];
    //发送成功
    [self.successCallbacks setObject:success forKey:dateTimeStr];
    //发送失败
    [self.failureCallbacks setObject:failure forKey:dateTimeStr];
    //保存消息
    [self.successMsgs setObject:chatMsg forKey:dateTimeStr];
    
    //写入请求数据
    [socket writeData:reqData withTimeout:-1 tag:dateTime];
    
}



//插入数据库
-(void)msgInsert:(ChatMessage*)msg{
    //我们先姑且认为它是最后一条
    ChatUser* user=[FlappyData getUser];
    //创建
    msg.messageSended=SEND_STATE_CREATE;
    //数据
    NSInteger value=(user.latest!=nil? user.latest.integerValue:0)+1;
    //还没发送成功，那么放在最后一条
    msg.messageTableSeq=value;
    //之前有没有
    ChatMessage* former=[[FlappyDataBase shareInstance] getMessageByID:msg.messageId];
    //没有就插入，有就更新
    if(former==nil){
        [[FlappyDataBase shareInstance] insert:msg];
    }else{
        [[FlappyDataBase shareInstance] updateMessage:msg];
    }
}

//发送成功
-(void)msgSuccess:(ChatMessage*)msg{
    //发送成功了
    msg.messageSended=SEND_STATE_SENDED;
    //放入指定的位置
    [[FlappyDataBase shareInstance] updateMessage:msg];
}

//发送失败
-(void)msgFailure:(ChatMessage*)msg{
    //发送成功了
    msg.messageSended=SEND_STATE_FAILURE;
    //放入指定的位置
    [[FlappyDataBase shareInstance] updateMessage:msg];
}

//成功
-(void)successCallback:(NSInteger)call{
    
    NSString* dateTimeStr=[NSString stringWithFormat:@"%ld",(long)call];
    
    //获取回调
    FlappySendSuccess success=[self.successCallbacks objectForKey:dateTimeStr];
    //消息
    ChatMessage* msg=[self.successMsgs objectForKey:dateTimeStr];
    //不为空
    if(success!=nil){
        //移除
        [self msgSuccess:msg];
        success(msg);
        [self.successCallbacks removeObjectForKey:dateTimeStr];
        [self.failureCallbacks removeObjectForKey:dateTimeStr];
        [self.successMsgs removeObjectForKey:dateTimeStr];
    }
}

//失败
-(void)failureCallback:(NSInteger)call{
    NSString* dateTimeStr=[NSString stringWithFormat:@"%ld",(long)call];
    //获取回调
    FlappySendFailure failure=[self.failureCallbacks objectForKey:dateTimeStr];
    //消息
    ChatMessage* msg=[self.successMsgs objectForKey:dateTimeStr];
    //不为空
    if(failure!=nil){
        //发送失败
        [self msgFailure:msg];
        //移除
        failure(msg,[NSError errorWithDomain:@"连接已经断开" code:0 userInfo:nil],RESULT_NETERROR);
        [self.successCallbacks removeObjectForKey:dateTimeStr];
        [self.failureCallbacks removeObjectForKey:dateTimeStr];
        [self.successMsgs removeObjectForKey:dateTimeStr];
    }
}


//全部失败
-(void)failureAllCallbacks{
    NSMutableDictionary* dic=self.failureCallbacks;
    for(NSString* time in dic)
    {
        [self failureCallback:[time integerValue]];
    }
}


@end
