//
//  ImageScaleTool.h
//  NineWeiWifi
//
//  Created by admin on 15-1-23.
//  Copyright (c) 2015年 NINEWEI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FlappyImageTool : NSObject


/*************************
 转换图片的大小，
 size为最大宽高
 *************************/
+(UIImage*)OriginImage:(UIImage *)image scaleByMaxsize:(CGSize)size andScale:(float)scale;
/*************************
 以当前dpi转换图片的大小，
 size为最大宽高
 *************************/
+(UIImage*)OriginImage:(UIImage *)image scaleByMaxsize:(CGSize)size;
/*************************
 转换图片的大小，
 最终图片在size 大小的image中fit显示
 *************************/
+(UIImage*)OriginImage:(UIImage *)image scaleCenterInSize:(CGSize)size;
/*************************
 转换图片的大小，
 *************************/
+(UIImage*) OriginImage:(UIImage *)image scaleToSize:(CGSize)size;
/*************************
 通过颜色创建一张纯色的图片
 *************************/
+(UIImage *)imageWithColor:(UIColor *)color;

//获取图片大小
+(CGSize)getImageSizeWithPath:(id)imageURL;
@end
