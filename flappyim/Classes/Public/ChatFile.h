//
//  ChatFile.h
//  flappyim
//
//  Created by li lin on 2023/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatFile : NSObject

//文件名称
@property(nonatomic,copy) NSString*  fileName;
//文件发送地址
@property(nonatomic,copy) NSString*  sendPath;
//文件网络地址
@property(nonatomic,copy) NSString*  path;

@end

NS_ASSUME_NONNULL_END
