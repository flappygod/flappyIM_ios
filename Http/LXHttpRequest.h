//
//  LXHttpRequest.h
//  Istudy
//
//  Created by macbook air on 16/7/10.
//  Copyright © 2016年 lipo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


//错误请求数据
typedef void(^ErrorBlock) (NSException *);

//请求正确数据
typedef void(^SuccessBlock) (NSString *);


@interface LXHttpRequest : NSObject<NSURLConnectionDelegate>


//异步请求时接收数据的data
@property(nonatomic,strong)  NSMutableData *receiveData;
//请求的tag
@property (nonatomic,copy) NSString*  tag;
//是否打开cookie
@property (nonatomic,assign) Boolean  enableCookie;
//地址
@property (nonatomic,copy) NSString*  url;
//参数
@property (nonatomic,strong) NSMutableDictionary* params;
//超时时间
@property (nonatomic,assign) NSInteger timeOut;
//cookie
@property (nonatomic,copy) NSString*  cookie;
//添加的请求参数
@property (nonatomic,strong) NSMutableDictionary*  headerProperty;


//失败代码块
@property (nonatomic, strong)ErrorBlock errorBlock;
//成功代码块
@property (nonatomic, strong)SuccessBlock successBlock;




//同步get请求
-(NSString*)syncGet:(NSError*)error;
//同步发送post请求
-(NSString*)syncPostAsJson:(NSError*)error;
//同步发送param形式的数据
-(NSString*)syncPostAsParam:(NSError*)error;





//异步开始get请求
-(void)get;
//异步以json形式进行post
-(void)postAsJson;
//异步以param形式进行post
-(void)postAsParam;



@end
