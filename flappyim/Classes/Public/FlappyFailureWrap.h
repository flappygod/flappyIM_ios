//
//  FlappyFailureWrap.h
//  AFNetworking
//
//  Created by lijunlin on 2020/9/14.
//

#import <Foundation/Foundation.h>
#import "FlappyBlocks.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlappyFailureWrap : NSObject

//失败
@property(nonatomic,strong) FlappyFailure failure;

//初始化
-(instancetype)initWithFailure:(FlappyFailure) failure;

//释放
-(void)completeBlock:(NSError*)error andCode:(NSInteger)integer;


@end

NS_ASSUME_NONNULL_END
