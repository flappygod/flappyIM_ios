//
//  ChatSystem.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/27.
//

#import <Foundation/Foundation.h>


#define ACTION_UPDATE_DONOTHING 0
#define ACTION_UPDATE_ONESESSION 1
#define ACTION_UPDATE_ALLSESSION 2

NS_ASSUME_NONNULL_BEGIN

@interface ChatSystem : NSObject

//系统动作
@property(nonatomic,assign) NSInteger  sysAction;
//标题
@property(nonatomic,copy) NSString*  sysTitle;
//内容
@property(nonatomic,copy) NSString*  sysBody;
//数据
@property(nonatomic,copy) NSString*  sysData;
//系统时间
@property(nonatomic,copy) NSString*  sysTime;



@end

NS_ASSUME_NONNULL_END
