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
    
    //注册远程通知
    [[FlappyIM shareInstance]registerRemoteNotice:application];
    
    //通知处理
    NSDictionary* pushNotificationKey = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(pushNotificationKey!=nil){
        [[FlappyIM shareInstance] didReceiveRemoteNotification:pushNotificationKey];
    }
    
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





/*
 用户点击了通知，进入到应用程序中，需要捕获到这个时机
 从而决定这一次的进入应用程序，到底要显示或执行什么动作，下面的方法就会在点击通知时自动调用
 */
/*
 1.应用程序在前台时：通知到，该方法自动执行
 2.应用程序在后台且没有退出时：通知到，只有点击了通知查看时，该方法自动执行
 3.应用程序退出：通知到，点击查看通知，不会执行下面的didReceive方法，而是只执行didFinishLauncing方法
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"USREINFO:%@",userInfo);
    //为了测试在应用程序退出后，该方法是否执行
    //所以往第一个界面上添加一个label，看标签是否会显示一些内容
    [[FlappyIM shareInstance] didReceiveRemoteNotification:userInfo];
    
}

//接收到消息
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification NS_DEPRECATED_IOS(4_0, 10_0, "Use UserNotifications Framework's -[UNUserNotificationCenterDelegate willPresentNotification:withCompletionHandler:] or -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:]") __TVOS_PROHIBITED{
    
    NSLog(@"USREINFO::::%@",notification);
    //所以往第一个界面上添加一个label，看标签是否会显示一些内容
    [[FlappyIM shareInstance] didReceiveRemoteNotification:notification.userInfo];
}


/*
 此方法是新的用于响应远程推送通知的方法
 1.如果应用程序在后台，则通知到，点击查看，该方法自动执行
 2.如果应用程序在前台，则通知到，该方法自动执行
 3.如果应用程序被关闭，则通知到，点击查看，先执行didFinish方法，再执行该方法
 4.可以开启后台刷新数据的功能
 step1：点击target-->Capabilities-->Background Modes-->Remote Notification勾上
 step2：在给APNs服务器发送的要推送的信息中，添加一组字符串如：
 {"aps":{"content-available":"999","alert":"bbbbb.","badge":1}}
 其中content-availabel就是为了配合后台刷新而添加的内容，999可以随意定义
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    NSLog(@"USREINFO::::%@",userInfo);
    
    [[FlappyIM shareInstance] didReceiveRemoteNotification:userInfo];
    //NewData就是使用新的数据 更新界面，响应点击通知这个动作
    completionHandler(UIBackgroundFetchResultNewData);
}








// 将得到的deviceToken传给SDK
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    //[[EaseMob sharedInstance] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    [[FlappyIM shareInstance] registerDeviceToken:deviceToken];
}

// 注册deviceToken失败
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    //[[EaseMob sharedInstance] application:application didFailToRegisterForRemoteNotificationsWithError:error];
    NSLog(@"失败");
}

@end
