//
//  flappyAppDelegate.m
//  flappyim
//
//  Created by 4c641e4c592086a8d563f6d22d5a3011013286f9 on 08/06/2019.
//  Copyright (c) 2019 4c641e4c592086a8d563f6d22d5a3011013286f9. All rights reserved.
//

#import "flappyAppDelegate.h"
#import <flappyim/FlappyIM.h>

@implementation flappyAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //
    //    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    //
    //    center.delegate = self;
    //    //消息推送注册
    //    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert +
    //                                             UNAuthorizationOptionSound +
    //                                             UNAuthorizationOptionBadge )
    //                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
    //                              if (!granted)
    //                              {
    //                                  NSLog(@"请开启推送功能否则无法收到推送通知");
    //                              }
    //                          }];
    //
    //
    //
    //    if (@available(iOS 11.0, *))
    //    {
    //        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    //        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
    //            if (!granted)
    //            {
    //                NSLog(@"请开启推送功能否则无法收到推送通知");
    //            }
    //        }];
    //    }
    //    else {
    //        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    //        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
    //                                                                                 categories:nil];
    //        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    //    }
    //    [[UIApplication sharedApplication] registerForRemoteNotifications];
    //
    //
    //
    //    // 注册push权限，用于显示本地推送
    //    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    //
    
    //注册远程通知
    [[FlappyIM shareInstance]registerRemoteNotice:application];
    
    
    
    return YES;
}




- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    //1. 处理通知
    
    
    
    //2. 处理完成后条用 completionHandler ，用于指示在前台显示通知的形式
    
    completionHandler(UNNotificationPresentationOptionAlert);
    
}


// 将得到的deviceToken传给SDK
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    //[[EaseMob sharedInstance] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    [[FlappyIM shareInstance] registerDeviceToken:deviceToken];
}

// 注册deviceToken失败
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    //[[EaseMob sharedInstance] application:application didFailToRegisterForRemoteNotificationsWithError:error];
    
}

@end
