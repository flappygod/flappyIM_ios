//
//  flappyViewController.m
//  flappyim
//
//  Created by 4c641e4c592086a8d563f6d22d5a3011013286f9 on 08/06/2019.
//  Copyright (c) 2019 4c641e4c592086a8d563f6d22d5a3011013286f9. All rights reserved.
//

#import "flappyViewController.h"
#import <flappyim/FlappyIM.h>


@interface flappyViewController ()

@end

@implementation flappyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[FlappyIM shareInstance] createAccount:@"105"
                                andUserName:@"小胖"
                                andUserHead:@"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=400062461,2874561526&fm=26&gp=0.jpg"
                                 andSuccess:^(id _Nullable data) {
                                     NSLog(@"成功收到请求");
                                 }
                                 andFailure:^(NSError * error, NSInteger code) {
                                     
                                 }];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
