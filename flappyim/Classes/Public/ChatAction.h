//
//  ChatAction.h
//  flappyim
//
//  Created by li lin on 2023/8/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatAction : NSObject


//操作类型
@property(nonatomic,assign) NSInteger  actionType;

//操作ID
@property(nonatomic,copy) NSArray*  actionIds;

@end

NS_ASSUME_NONNULL_END
