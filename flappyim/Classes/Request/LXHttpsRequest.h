//
//  LXHttpsRequest.h
//  zhichuangyanbao
//
//  Created by macbook air on 16/12/16.
//  Copyright © 2016年 zhichuangyanbao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//错误请求数据
typedef void(^ErrorBlock) (NSError *);

//请求正确数据
typedef void(^SuccessBlock) (NSString *);



@interface LXHttpsRequest : NSObject<NSURLSessionDelegate>


//异步请求时接收数据的data
@property(nonatomic,strong)   NSMutableData *receiveData;
//是否打开cookie
@property (nonatomic,assign)  Boolean       enableCookie;
//超时时间
@property (nonatomic,assign)  NSInteger     timeOut;
//加密Uuid
@property (nonatomic,assign) NSString* dataUuid;
//加密Key
@property (nonatomic,assign) NSString* dataKey;
//请求的tag
@property (nonatomic,copy)    NSString*     tag;
//地址
@property (nonatomic,copy)    NSString*     url;
//cookie
@property (nonatomic,copy)    NSString*     cookie;
//参数
@property (nonatomic,strong)  NSMutableDictionary* params;
//添加的请求参数
@property (nonatomic,strong)  NSMutableDictionary*  headerProperty;
//失败代码块
@property (nonatomic, strong) ErrorBlock    errorBlock;
//成功代码块
@property (nonatomic, strong) SuccessBlock  successBlock;



//异步以json形式进行post
-(void)postAsJson;


@end
