//
//  UploadModel.h
//  flappyim
//
//  Created by lijunlin on 2019/8/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlappyUploadModel : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *fileName;

@end

NS_ASSUME_NONNULL_END
