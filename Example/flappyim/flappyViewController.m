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
    
    
    [[FlappyIM shareInstance] setup];
    
    //创建登录
    UITapGestureRecognizer* gs=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(login)];
    [self.view addGestureRecognizer:gs];
    // Do any additional setup after loading the view, typically from a nib.
}


//登录
-(void)login{
    [[FlappyIM shareInstance] login:@"101" andSuccess:^(id data) {
        //登录成功
        NSLog(@"登录成功");
    } andFailure:^(NSError * error, NSInteger code) {
        NSLog(@"登录失败");
    }];
    
    __weak typeof(self) safeSelf=self;
    [[FlappyIM shareInstance] addListener:^(ChatMessage * _Nullable message) {
        safeSelf.lable.text=message.messageContent;
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
