//
//  ChatLocation.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatLocation : NSObject

//经纬度
@property(nonatomic,copy) NSString* lat;
@property(nonatomic,copy) NSString* lng;
//地址名称
@property(nonatomic,copy) NSString* address;


@end

NS_ASSUME_NONNULL_END
