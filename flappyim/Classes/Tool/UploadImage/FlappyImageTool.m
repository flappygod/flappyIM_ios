//
//  ImageScaleTool.m
//  NineWeiWifi
//
//  Created by admin on 15-1-23.
//  Copyright (c) 2015年 NINEWEI. All rights reserved.
//

#import "FlappyImageTool.h"
#import <ImageIO/ImageIO.h>

@implementation FlappyImageTool



//改变图片
+(UIImage*)OriginImage:(UIImage *)image scaleByMaxsize:(CGSize)size andScale:(float)scale{
    if(image.size.width<size.width&&image.size.height<size.height){
        return image;
    }
    
    //size 为CGSize类型，即你所需要的图片尺寸
    float xy=image.size.width/image.size.height;
    float xy2=size.width/size.height;
    if(xy>xy2){
        CGRect rect=CGRectMake(0, 0, size.width, size.width/xy);
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, scale);
        [image drawInRect:rect];
    }else{
        CGRect rect=CGRectMake(0, 0, size.height*xy, size.height);
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, scale);
        [image drawInRect:rect];
    }
    
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    //返回的就是已经改变的图片
    return scaledImage;
}


//改变图片
+(UIImage*)OriginImage:(UIImage *)image scaleByMaxsize:(CGSize)size{
    if(image.size.width<size.width&&image.size.height<size.height){
        return image;
    }
    
    
    //size 为CGSize类型，即你所需要的图片尺寸
    
    float xy=image.size.width/image.size.height;
    float xy2=size.width/size.height;
    
    if(xy>xy2){
        
        CGRect rect=CGRectMake(0, 0, size.width, size.width/xy);
        
        float f=[[UIScreen mainScreen] scale];
        if(f == 2.0){
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 2.0);
        }else if(f == 3.0){
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 3.0);
        }else{
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, f);
        }
        
        [image drawInRect:rect];
    }else{
        
        CGRect rect=CGRectMake(0, 0, size.height*xy, size.height);
        
        float f=[[UIScreen mainScreen] scale];
        if(f == 2.0){
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 2.0);
        }else if(f == 3.0){
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 3.0);
        }else{
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, f);
        }
        
        [image drawInRect:rect];
    }
    
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    //返回的就是已经改变的图片
    return scaledImage;
}


//改变图片的大小，不对图片做拉伸处理，但是最后图片的大小由size决定
+(UIImage*)OriginImage:(UIImage *)image scaleCenterInSize:(CGSize)size{
    
    if(image.size.width<size.width&&image.size.height<size.height){
        return image;
    }
    
    float f=[[UIScreen mainScreen] scale];
    if(f == 2.0){
        UIGraphicsBeginImageContextWithOptions(size, NO, 2.0);
    }else if(f == 3.0){
        UIGraphicsBeginImageContextWithOptions(size, NO, 3.0);
    }else{
        UIGraphicsBeginImageContextWithOptions(size, NO, f);
        //UIGraphicsBeginImageContext(size);
    }
    //size 为CGSize类型，即你所需要的图片尺寸
    
    float xy=image.size.width/image.size.height;
    float xy2=size.width/size.height;
    
    if(xy>xy2){
        [image drawInRect:CGRectMake(0, (size.height-size.width/xy)/2, size.width, size.width/xy)];
    }else{
        [image drawInRect:CGRectMake((size.width-size.height*xy)/2, 0, size.height*xy, size.height)];
    }
    
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    //返回的就是已经改变的图片
    return scaledImage;
}


//改变图片的大小，这里可能会对图片进行拉伸处理
+(UIImage*) OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    
    float f=[[UIScreen mainScreen] scale];
    if(f == 2.0){
        UIGraphicsBeginImageContextWithOptions(size, NO, 2.0);
    }else if(f == 3.0){
        UIGraphicsBeginImageContextWithOptions(size, NO, 3.0);
    }else{
        UIGraphicsBeginImageContextWithOptions(size, NO, f);
    }
    //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    //返回的就是已经改变的图片
    return scaledImage;
}


//通过颜色建造一张图片
+(UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


// 根据图片url获取图片尺寸
+(CGSize)getImageSizeWithPath:(id)imageURL
{
    NSString* trueUrl=imageURL;
    if(![trueUrl hasPrefix:@"file://"]){
        trueUrl = [NSString stringWithFormat: @"%@%@",@"file://",trueUrl];
    }
    CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)[NSURL URLWithString:trueUrl], NULL);
    NSDictionary* imageHeader = (__bridge NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    NSLog(@"Image header info %@",imageHeader);
    CGFloat pixelHeight = [[imageHeader objectForKey:@"PixelHeight"] floatValue];
    CGFloat pixelWidth  = [[imageHeader objectForKey:@"PixelWidth"] floatValue];
    CGSize size = CGSizeMake(pixelWidth, pixelHeight);
    return  size;
}

@end
