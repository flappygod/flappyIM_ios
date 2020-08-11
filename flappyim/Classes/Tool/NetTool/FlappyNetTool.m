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
    
    if ( [netWorkState isEqualToString:@"Not Reachable"]) {
        return 0;
    }
    // 未知
    else if([netWorkState isEqualToString:@"Unknow"]){
        return -1;
    }
    // 蜂窝数据
    else if ([netWorkState isEqualToString:@"Reachable via WWAN"]) {
        return 1;
    }
    // WiFi
    else {
        
        return 2;
        
    }
    
}


@end
