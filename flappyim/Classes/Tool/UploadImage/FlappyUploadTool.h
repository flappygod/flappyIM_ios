//
//  UploadImageTool.h
//  driver
//
//  Created by macbook air on 16/8/5.
//  Copyright © 2016年 airportexpress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlappyUploadModel.h"

//错误请求数据
typedef void(^ErrorBlock) (NSException *);
//请求正确数据
typedef void(^SuccessBlock) (id);
//工具
@interface FlappyUploadTool : NSObject


//异步请求时接收数据的data
@property(nonatomic,strong)  NSMutableData *receiveData;

//失败代码块
@property (nonatomic, strong) ErrorBlock errorBlock;

//成功代码块
@property (nonatomic, strong) SuccessBlock successBlock;





//上传文件到服务器
- (void)uploadImageAndMovieBaseModel:(NSString*)urlPath
                            andModel:(FlappyUploadModel *)model;


@end
