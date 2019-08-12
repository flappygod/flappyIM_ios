//
//  ChatImage.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatImage : NSObject

//发送的本地地址
@property(nonatomic,copy) NSString*  sendPath;
//地址
@property(nonatomic,copy) NSString*  path;
//宽度
@property(nonatomic,copy) NSString*  width;
//高度
@property(nonatomic,copy) NSString*  height;



@end

NS_ASSUME_NONNULL_END
