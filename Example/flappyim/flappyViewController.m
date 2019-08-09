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

@property(nonatomic,strong) FlappySession* session;

@end

@implementation flappyViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [[FlappyIM shareInstance] setup];
    
    //创建登录
    UITapGestureRecognizer* gs=[[UITapGestureRecognizer alloc]initWithTarget:self
                                                                      action:@selector(login)];
    [self.view addGestureRecognizer:gs];
    
    //发送
    [self.sendBtn addTarget:self
                     action:@selector(sendMessage:)
           forControlEvents:UIControlEventTouchUpInside];
    
    //创建会话
    [self.create addTarget:self
                    action:@selector(createSession)
          forControlEvents:UIControlEventTouchUpInside];
    
}


//创建session
-(void)createSession{
    //创建session
    __weak typeof(self) safeSelf=self;
    [[FlappyIM shareInstance] createSession:@"100"
                                 andSuccess:^(id _Nullable data) {
                                     safeSelf.session=data;
                                     
                                     [safeSelf.session setMessageListener:^(ChatMessage * _Nullable message) {
                                         
                                     }];
                                     
                                 } andFailure:^(NSError * _Nullable error, NSInteger code) {
                                     
                                 }];
}


//登录
-(void)login{
    [[FlappyIM shareInstance] login:@"101" andSuccess:^(id data) {
        //登录成功
        NSLog(@"登录成功");
    } andFailure:^(NSError * error, NSInteger code) {
        NSLog(@"登录失败");
    }];
}

//发送消息
-(void)sendMessage:(id)sender{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
