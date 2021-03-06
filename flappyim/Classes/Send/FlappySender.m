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
            //地址
            chatVoice.path=dic[@"resultData"][@"filePath"];
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
            failure(chatMsg,[NSError errorWithDomain:@"图片上传失败" code:0 userInfo:nil],
                    RESULT_NETERROR);
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }
    };
    
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf msgFailure:chatMsg];
        //上传失败了
        failure(chatMsg,[NSError errorWithDomain:error.reason code:0 userInfo:nil],
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
            failure(chatMsg,[NSError errorWithDomain:@"音频读取失败" code:0 userInfo:nil],
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
        failure(chatMsg,[NSError errorWithDomain:@"音频读取失败" code:0 userInfo:nil],
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
            NSString* imgPath=dic[@"resultData"][@"filePath"];
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
        failure(chatMsg,[NSError errorWithDomain:error.description code:0 userInfo:nil],
                RESULT_NETERROR);
        [safeSelf.reqArray removeObject:safeReq];
    };
    
    @try {
        //获取图片
        UIImage* image=[[UIImage alloc]initWithContentsOfFile:chatImg.sendPath];
        //不为空
        if(image==nil){
            [self msgFailure:chatMsg];
            failure(chatMsg,[NSError errorWithDomain:@"图片读取失败" code:0 userInfo:nil],
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
    
    //消息
    [self msgInsert:chatMsg];
    
    //视频信息
    ChatVideo* chatVideo=[ChatVideo mj_objectWithKeyValues:[FlappyJsonTool JSONStringToDictionary:chatMsg.messageContent]];
    
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
            //地址
            chatVideo.path=dic[@"resultData"][@"filePath"];
            chatVideo.coverPath=dic[@"resultData"][@"overFilePath"];
            //设置
            chatMsg.messageContent=[FlappyJsonTool DicToJSONString:[chatVideo mj_keyValues]];
            //上传完成发送消息
            [safeSelf sendMessage:chatMsg
                       andSuccess:success
                       andFailure:failure];
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }else{
            [safeSelf msgFailure:chatMsg];
            //上传失败了
            failure(chatMsg,[NSError errorWithDomain:@"图片上传失败" code:0 userInfo:nil],
                    RESULT_NETERROR);
            //移除请求释放资源
            [safeSelf.reqArray removeObject:safeReq];
        }
    };
    
    //失败
    req.errorBlock=^(NSException*  error){
        [safeSelf msgFailure:chatMsg];
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
        if(info!=nil&&info.overPath!=nil&&info.duration!=nil&&info.vwidth!=nil&&info.vheight!=nil){
            
        }else{
            @throw [[NSException alloc]initWithName:@"视频解析失败"
                                             reason:@"视频解析失败"
                                           userInfo:nil];
        }
        
        chatVideo.width=info.vwidth;
        chatVideo.height=info.vheight;
        chatVideo.duration=info.duration;
        
        //上传文件
        FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
        uploadReq.path=info.overPath;
        uploadReq.name=@"overFile";
        uploadReq.type=@"image";
        [uplaods addObject:uploadReq];
        
    } @catch (NSException *exception) {
        [self msgFailure:chatMsg];
        failure(chatMsg,[NSError errorWithDomain:@"音频读取失败" code:0 userInfo:nil],
                RESULT_FILEERR);
        return;
    } @finally {
        
    }
    
    //上传文件
    FlappyUploadModel* uploadReq=[[FlappyUploadModel alloc]init];
    //发送地址
    uploadReq.path=chatVideo.sendPath;
    //文件
    uploadReq.name=@"file";
    //视频
    uploadReq.type=@"video";
    //上传
    [uplaods addObject:uploadReq];
    
    [req uploadImageAndMovieBaseModel:[FlappyApiConfig shareInstance].URL_videoUpload
                            andModels:uplaods];
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
    
    //之前的回调错误信息
    ChatMessage* former=[self.successMsgs objectForKey:chatMsg.messageId];
    if(former!=nil){
        [self failureCallback:chatMsg.messageId];
    }
    
    
    //发送消息轻轻
    FlappyRequest* request=[[FlappyRequest alloc]init];
    //消息请求
    request.type=REQ_MSG;
    //消息内容
    request.msg=[FlappyBaseSession changeToMessage:chatMsg];
    
    //请求数据，已经GPBComputeRawVarint32SizeForInteger
    NSData* reqData=[request delimitedData];
    //消息ID保存
    [self.successCallbacks setObject:success forKey:chatMsg.messageId];
    //消息ID保存
    [self.failureCallbacks setObject:failure forKey:chatMsg.messageId];
    //消息ID保存
    [self.successMsgs setObject:chatMsg forKey:chatMsg.messageId];
    
    long time=(long)[NSDate date].timeIntervalSince1970*1000;
    //写入请求数据
    [socket writeData:reqData withTimeout:-1 tag:time];
    
}



//插入数据库
-(void)msgInsert:(ChatMessage*)msg{
    //我们先姑且认为它是最后一条
    ChatUser* user=[[FlappyData shareInstance]getUser];
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
        [[FlappyDataBase shareInstance] insertMsg:msg];
    }else{
        //否则更新
        [[FlappyDataBase shareInstance] updateMessage:msg];
    }
}



//发送失败
-(void)msgFailure:(ChatMessage*)msg{
    //发送成功了
    msg.messageSended=SEND_STATE_FAILURE;
    //放入指定的位置
    [[FlappyDataBase shareInstance] updateMessage:msg];
}

//成功
-(void)successCallback:(ChatMessage*)chatMsg{
    
    if(chatMsg==nil){
        return;
    }
    
    //获取回调
    FlappySendSuccess success=[self.successCallbacks objectForKey:chatMsg.messageId];
    //不为空
    if(success!=nil){
        //消息回调，成功的消息已经正常写入了
        success(chatMsg);
        [self.successCallbacks removeObjectForKey:chatMsg.messageId];
        [self.failureCallbacks removeObjectForKey:chatMsg.messageId];
        [self.successMsgs removeObjectForKey:chatMsg.messageId];
    }
}

//失败
-(void)failureCallback:(NSString*)messageid{
    if(messageid==nil){
        return;
    }
    //获取回调
    FlappySendFailure failure=[self.failureCallbacks objectForKey:messageid];
    //消息
    ChatMessage* msg=[self.successMsgs objectForKey:messageid];
    //不为空
    if(failure!=nil&&msg!=nil){
        //发送失败
        [self msgFailure:msg];
        //移除
        failure(msg,[NSError errorWithDomain:@"连接已经断开" code:0 userInfo:nil],RESULT_NETERROR);
        [self.successCallbacks removeObjectForKey:messageid];
        [self.failureCallbacks removeObjectForKey:messageid];
        [self.successMsgs removeObjectForKey:messageid];
    }
}


//全部失败
-(void)failureAllCallbacks{
    //没有的时候饭很好
    if(self.failureCallbacks==nil||self.failureCallbacks.count==0){
        return;
    }
    //回调信息
    NSMutableDictionary* dic=self.failureCallbacks;
    //所有的
    NSArray* array=dic.allKeys;
    //都失败
    for(int s=0;s<array.count;s++){
        NSString* messageid=[array objectAtIndex:s];
        [self failureCallback:messageid];
    }
    
}



// 获取视频第一帧
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
