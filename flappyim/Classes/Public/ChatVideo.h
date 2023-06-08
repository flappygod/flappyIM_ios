//
//  ChatVideo.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatVideo : NSObject

//地址
@property(nonatomic,copy) NSString*  path;
//发送的本地地址
@property(nonatomic,copy) NSString*  sendPath;
//封面图片
@property(nonatomic,copy) NSString*  coverPath;
//封面图片
@property(nonatomic,copy) NSString*  coverSendPath;
//时长
@property(nonatomic,copy) NSString*  duration;
//宽度
@property(nonatomic,copy) NSString*  width;
//高度
@property(nonatomic,copy) NSString*  height;


@end

NS_ASSUME_NONNULL_END
