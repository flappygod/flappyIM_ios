//
//  SessionGroupData.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/13.
//

#import "SessionData.h"

@implementation SessionData


+ (NSDictionary *)mj_objectClassInArray {
    //前边，是属性数组的名字，后边就是类名
    return @{@"users" : @"ChatUser"};
}



@end
