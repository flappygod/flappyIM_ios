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

//用于会话展示的文本
@property(nonatomic,copy) NSString*  sysText;

//系统动作的文本
@property(nonatomic,assign) NSInteger  sysAction;

//系统动作的数据
@property(nonatomic,copy) NSString*  sysActionData;


@end

NS_ASSUME_NONNULL_END
