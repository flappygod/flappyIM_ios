//
//  FlappySender.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import "FlappySender.h"


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
    });
    //初始化
    _sharedSingleton.successCallbacks=[[NSMutableDictionary alloc]init];
    _sharedSingleton.failureCallbacks=[[NSMutableDictionary alloc]init];
    _sharedSingleton.successMsgs=[[NSMutableDictionary alloc]init];
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
    NSInteger  dateTime=[[NSDate date] timeIntervalSince1970]*1000;
    
    //发送成功
    self.successCallbacks setObject:success forKey:dateTime];
    //发送失败
    self.failureCallbacks setObject:failure forKey:dateTime];
    //保存消息
    self.successMsgs setObject:ChatMessage forKey:dateTime];
    
    //写入请求数据
    [socket writeData:reqData withTimeout:-1 tag:dateTime];
    
}


//成功
-(void)successCallback:(NSInteger)call{
    //获取回调
    FlappySuccess success=[self.successCallbacks objectForKey:call];
    //消息
    ChatMessage* msg=[self.successMsgs objectForKey:call];
    //不为空
    if(success!=nil){
        //移除
        success(msg);
        [self.successCallbacks removeObjectForKey:tag];
        [self.failureCallbacks removeObjectForKey:tag];
        [self.successMsgs removeObjectForKey:tag];
    }
}

//失败
-(void)failureCallbacl:(NSInteger)call{
    //获取回调
    FlappyFailure failure=[self.failureCallbacks objectForKey:call];
    //消息
    ChatMessage* msg=[self.successMsgs objectForKey:call];
    //不为空
    if(failure!=nil){
        //移除
        failure(msg);
        [self.successCallbacks removeObjectForKey:tag];
        [self.failureCallbacks removeObjectForKey:tag];
        [self.successMsgs removeObjectForKey:tag];
    }
}



@end
