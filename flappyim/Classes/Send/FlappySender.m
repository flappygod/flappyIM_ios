//
//  FlappySender.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import "FlappySender.h"
#import "DataBase.h"
#import "FlappyData.h"


@interface FlappySender()


//成功
@property(nonatomic,strong) NSMutableDictionary* successCallbacks;

//失败
@property(nonatomic,strong) NSMutableDictionary* failureCallbacks;

//消息
@property(nonatomic,strong) NSMutableDictionary* successMsgs;

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

//发送消息
-(void)sendMessage:(Message*)msg
       withChatMsg:(ChatMessage*)chatMsg
        andSuccess:(FlappySuccess)success
        andFailure:(FlappyFailure) failure{
    
    //获取socket
    GCDAsyncSocket* socket=self.socket;
    //创建
    if(socket==nil){
        failure([NSError errorWithDomain:@"连接已断开" code:0 userInfo:nil],RESULT_NETERROR);
        return;
    }
    
    //连接到服务器开始请求登录
    FlappyRequest* request=[[FlappyRequest alloc]init];
    //登录请求
    request.type=REQ_MSG;
    //登录信息
    request.msg=msg;
    
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
        
        //获取当前的用户
        ChatUser* user=[FlappyData getUser];
        
        //这里其实我们可以认为已经发送成功了,
        msg.messageSended=SEND_STATE_SENDED;
        //发送成功了，因为服务器还没有返回messageTableSeq，我们暂且认为是最后一条，这样，保证显示的位置
        msg.messageTableSeq=user.latest;
        //放入指定的位置
        [[DataBase shareInstance] insert:msg];
        
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
        
        //发送失败的情况下，消息始终在最后一条
        msg.messageSended=SEND_STATE_FAILURE;
        //插入失败的数据
        [[DataBase shareInstance] insert:msg];
        
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
