//
//  NetTool.m
//  flappyim
//
//  Created by lijunlin on 2019/8/8.
//

#import "FlappyNetTool.h"
#import <AFNetworking/AFNetworking.h>

@implementation FlappyNetTool


/**
 
 *  获取当前网络状态
 
 *
 
 *  0:无网络 & 1:2G & 2:3G & 3:4G & 5:WIFI
 
 */

+(NSInteger)getCurrentNetworkState {
    
    NSString *netWorkState = [[AFNetworkReachabilityManager sharedManager] localizedNetworkReachabilityStatusString];
    
    /*
     
     AFNetworkReachabilityStatusUnknown          = -1,
     
     AFNetworkReachabilityStatusNotReachable     = 0,
     
     AFNetworkReachabilityStatusReachableViaWWAN = 1,
     
     AFNetworkReachabilityStatusReachableViaWiFi = 2,
     
     */
    
    NSLog(@"NewWorkState --- %@", netWorkState);
    
    
    
    if ([netWorkState isEqualToString:@"Unknow"] || [netWorkState isEqualToString:@"Not Reachable"]) {// 未知 或 无网络
        
        return 0;
        
    }
    
    else if ([netWorkState isEqualToString:@"Reachable via WWAN"]) {// 蜂窝数据
        
        return 1;
        
    }
    
    else {// WiFi
        
        return 2;
        
    }
    
}


@end
