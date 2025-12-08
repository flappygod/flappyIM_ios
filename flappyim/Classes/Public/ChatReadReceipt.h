//
//  ChatReadReceipt.h
//  flappyim
//
//  Created by Lijunlin on 2025/12/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatReadReceipt : NSObject


@property(nonatomic,copy) NSString* userId;

@property(nonatomic,copy) NSString* sessionId;

@property(nonatomic,copy) NSString* readOffset;


@end

NS_ASSUME_NONNULL_END
