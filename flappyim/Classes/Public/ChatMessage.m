//
//  ChatMessage.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import "ChatMessage.h"

@implementation ChatMessage


+(NSArray *)indices
{
    NSArray *index1 = [NSArray arrayWithObject:@"messageId"];
    NSArray *index2 = [NSArray arrayWithObject:@"messageTableSeq"];
    return [NSArray arrayWithObjects:index1,index2,nil];
}


@end
