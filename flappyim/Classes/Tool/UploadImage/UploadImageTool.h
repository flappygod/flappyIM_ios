//
//  UploadImageTool.h
//  driver
//
//  Created by macbook air on 16/8/5.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import <Foundation/Foundation.h>

//错误请求数据
typedef void(^ErrorBlock) (NSException *);
//请求正确数据
typedef void(^SuccessBlock) (NSString *);
//工具
@interface UploadImageTool : NSObject


//异步请求时接收数据的data
@property(nonatomic,strong)  NSMutableData *receiveData;


//失败代码块
@property (nonatomic, strong)ErrorBlock errorBlock;
//成功代码块
@property (nonatomic, strong)SuccessBlock successBlock;


//上传图片到服务器
-(void)uploadImage:(NSString*)urlPath
        andMParams:(NSMutableDictionary*)params
          andImage:(NSMutableDictionary*)images;


@end