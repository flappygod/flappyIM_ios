//
//  HBAsynTask.h
//  SalesPlus
//
//  Created by macbook air on 16/1/9.
//  Copyright © 2016年 macbook air. All rights reserved.
//

#import <Foundation/Foundation.h>

//线程执行的block
typedef id(^ThreadRun)(void);
//线程执行完成
typedef void(^ThreadDone)(id);
//线程错误
typedef void(^ThreadError)(id);


@interface HBAsynTask : NSObject

//完成
@property (nonatomic,strong) ThreadDone  doneBlock;
//出错
@property (nonatomic,strong) ThreadError  errorBlock;

//开始执行
-(void)startThread:(ThreadRun)_runblock;

//构造器
-(instancetype)initWithBlock:(ThreadDone)  done andError:(ThreadError) error;
@end
