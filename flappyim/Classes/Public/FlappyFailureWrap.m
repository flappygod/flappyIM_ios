//
//  FlappyFailureWrap.m
//  AFNetworking
//
//  Created by lijunlin on 2020/9/14.
//

#import "FlappyFailureWrap.h"

@implementation FlappyFailureWrap

//进行初始化
-(instancetype)initWithFailure:(FlappyFailure) failure{
    self=[super init];
    if(self){
        _failure=failure;
    }
    return self;
}

//释放
-(void)completeBlock:(NSError*)error andCode:(NSInteger)integer{
    if(_failure!=nil){
        _failure(error,integer);
        _failure=nil;
    }
}


@end
