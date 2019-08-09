//
//  SessionModel.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface SessionModel : NSObject

//用户一
@property(nonatomic,strong) User*  userOne;
//用户二
@property(nonatomic,strong) User*  userTwo;


@end

NS_ASSUME_NONNULL_END
