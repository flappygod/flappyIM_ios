//
//  FlappySender.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import "FlappySender.h"
#import "FlappyBaseSession.h"
#import "UploadImageTool.h"
#import "MJExtension.h"
#import "JsonTool.h"
#import "ImageTool.h"
#import "DataBase.h"
#import "FlappyData.h"
#import <AVFoundation/AVAsset.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>


@interface FlappySender()


//成功
@property(nonatomic,strong) NSMutableDictionary* successCallbacks;

//失败
@property(nonatomic,strong) NSMutableDictionary* failureCallbacks;

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
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure{
    
    //图片信息
    ChatVoice* chatVoice=[ChatVoice mj_objectWithKeyValues:[JsonTool JSONStringToDictionary:chatMsg.messageContent]];
    
    //开始请求
    UploadImageTool* req=[[UploadImageTool alloc]init];
    
    
    
    //自己
    __weak typeof(self) safeSelf=self;
    __weak typeof (req) safeReq=req;
    
    //成功
    req.successBlock=^(id data){
        //字典
        NSDictionary* dic=data;
        //地址赋值
        chatVoice.path=dic[@"resultData"];
        //设置
        chatMsg.messageContent=[JsonTool DicToJSONString:[chatVoice mj_keyValues]];
        //上传完成发送消息
        [safeSelf sendMessage:chatMsg
                   andSuccess:success
                   andFailure:failure];
        
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf msgFailure:chatMsg];
        //上传失败了
        failure([NSError errorWithDomain:error.description code:0 userInfo:nil],
                RESULT_NETERROR);
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    //地址
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:chatVoice.sendPath]
                                                 options:nil];
    //获取长度
    if(audioAsset==nil){
        failure([NSError errorWithDomain:@"音频读取失败" code:0 userInfo:nil],RESULT_NETERROR);
        return;
    }
    
    //长度
    CMTime audioDuration = audioAsset.duration;
    //seconds
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    //长度
    chatVoice.seconds=[NSString stringWithFormat:@"%ld",(long)audioDurationSeconds*1000];
    
    
    
    UploadModel* iup=[[UploadModel alloc]init];
    iup.path=chatVoice.sendPath;
    iup.name=@"file";
    iup.type=@"video";
    
    [req uploadImageAndMovieBaseModel:URL_uploadUrl
                             andModel:iup];
    //添加
    [self.reqArray addObject:req];
    
}


//上传图片并发送
-(void)uploadImageAndSend:(ChatMessage*)chatMsg
               andSuccess:(FlappySuccess)success
               andFailure:(FlappyFailure)failure{
    
    //图片信息
    ChatImage* chatImg=[ChatImage mj_objectWithKeyValues:[JsonTool JSONStringToDictionary:chatMsg.messageContent]];
    
    //开始请求
    UploadImageTool* req=[[UploadImageTool alloc]init];
    
    //自己
    __weak typeof(self) safeSelf=self;
    __weak typeof (req) safeReq=req;
    
    //成功
    req.successBlock=^(id data){
        //字典
        NSDictionary* dic=data;
        //地址
        NSString* imgPath=dic[@"resultData"];
        //地址赋值
        chatImg.path=imgPath;
        //设置
        chatMsg.messageContent=[JsonTool DicToJSONString:[chatImg mj_keyValues]];
        //上传完成发送消息
        [safeSelf sendMessage:chatMsg
                   andSuccess:success
                   andFailure:failure];
        [safeSelf.reqArray removeObject:safeReq];
    };
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf msgFailure:chatMsg];
        //上传失败了
        failure([NSError errorWithDomain:error.description code:0 userInfo:nil],
                RESULT_NETERROR);
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    //获取图片
    UIImage* image=[[UIImage alloc]initWithContentsOfFile:chatImg.sendPath];
    //不为空
    if(image==nil){
        [self msgFailure:chatMsg];
        failure([NSError errorWithDomain:@"图片读取失败" code:0 userInfo:nil],RESULT_NETERROR);
        return;
    }
    
    //保存宽度
    chatImg.width=[NSString stringWithFormat:@"%ld",(long)image.size.width];
    //保存高度
    chatImg.height=[NSString stringWithFormat:@"%ld",(long)image.size.height];
    
    //上传
    UploadModel* iup=[[UploadModel alloc]init];
    iup.path=chatImg.sendPath;
    iup.name=@"file";
    iup.type=@"image";
    
    [req uploadImageAndMovieBaseModel:URL_uploadUrl
                             andModel:iup];
    
    //添加
    [self.reqArray addObject:req];
    
}


//发送消息
-(void)sendMessage:(ChatMessage*)chatMsg
        andSuccess:(FlappySuccess)success
        andFailure:(FlappyFailure) failure{
    
    //消息
    [self msgInsert:chatMsg];
    
    //获取socket
    GCDAsyncSocket* socket=self.socket;
    
    //连接已经断开了
    if(socket==nil){
        [self msgFailure:chatMsg];
        failure([NSError errorWithDomain:@"连接已断开" code:0 userInfo:nil],RESULT_NETERROR);
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
    //最后一条
    NSString* str=[NSString stringWithFormat:@"%ld",(long)value];
    //还没发送成功，那么放在最后一条
    msg.messageTableSeq=str;
    //之前有没有
    ChatMessage* former=[[DataBase shareInstance] getMessageByID:msg.messageId];
    //没有就插入，有就更新
    if(former==nil){
        [[DataBase shareInstance] insert:msg];
    }else{
        [[DataBase shareInstance] updateMessage:msg];
    }
}

//发送成功
-(void)msgSuccess:(ChatMessage*)msg{
    //发送成功了
    msg.messageSended=SEND_STATE_SENDED;
    //放入指定的位置
    [[DataBase shareInstance] updateMessage:msg];
}

//发送失败
-(void)msgFailure:(ChatMessage*)msg{
    //发送成功了
    msg.messageSended=SEND_STATE_FAILURE;
    //放入指定的位置
    [[DataBase shareInstance] updateMessage:msg];
}

//成功
-(void)successCallback:(NSInteger)call{
    
    NSString* dateTimeStr=[NSString stringWithFormat:@"%ld",(long)call];
    
    //获取回调
    FlappySuccess success=[self.successCallbacks objectForKey:dateTimeStr];
    //消息
    ChatMessage* msg=[self.successMsgs objectForKey:dateTimeStr];
    //不为空
    if(success!=nil){
        //移除
        success(msg);
        [self msgSuccess:msg];
        [self.successCallbacks removeObjectForKey:dateTimeStr];
        [self.failureCallbacks removeObjectForKey:dateTimeStr];
        [self.successMsgs removeObjectForKey:dateTimeStr];
    }
}

//失败
-(void)failureCallback:(NSInteger)call{
    NSString* dateTimeStr=[NSString stringWithFormat:@"%ld",(long)call];
    //获取回调
    FlappyFailure failure=[self.failureCallbacks objectForKey:dateTimeStr];
    //消息
    ChatMessage* msg=[self.successMsgs objectForKey:dateTimeStr];
    //不为空
    if(failure!=nil){
        //发送失败
        [self msgFailure:msg];
        //移除
        failure([NSError errorWithDomain:@"连接已经断开" code:0 userInfo:nil],RESULT_NETERROR);
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
