//
//  FlappySender.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>


@interface FlappySender : NSObject

//socket通信
@property (nonatomic,strong) GCDAsyncSocket*  socket;

//单例模式
+ (instancetype)shareInstance;

@end
