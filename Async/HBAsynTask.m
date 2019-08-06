//
//  HBAsynTask.m
//  SalesPlus
//
//  Created by macbook air on 16/1/9.
//  Copyright © 2016年 macbook air. All rights reserved.
//

#import "HBAsynTask.h"

@implementation HBAsynTask



//初始化
-(instancetype)initWithBlock:(ThreadDone)  done andError:(ThreadError) error{
    self=[super init];
    if(self!=nil){
        self.doneBlock=done;
        self.errorBlock=error;
    }
    return  self;
}


//开始线程
-(void)startThread:(ThreadRun)_runblock{
    [NSThread detachNewThreadSelector:@selector(threadRun:) toTarget:self withObject:_runblock];
}

//开始执行线程
-(void)threadRun:(ThreadRun)_runblock{
    id  ret;
    @try {
        if(_runblock!=nil)
        {
            ret=_runblock();
        }
        [self performSelectorOnMainThread:@selector(getDataDone:) withObject:ret waitUntilDone:NO];
    }
    @catch (NSException *exception) {
        [self performSelectorOnMainThread:@selector(error:) withObject:exception waitUntilDone:NO];
    }
}

//完成
-(void)getDataDone:(id)ret{
    if(_doneBlock!=nil){
        _doneBlock(ret);
    }
}
//完成
-(void)error:(NSException*)ret{
    if(_errorBlock!=nil){
        _errorBlock(ret);
    }
}

@end
