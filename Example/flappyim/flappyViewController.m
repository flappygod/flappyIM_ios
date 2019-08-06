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
    
    //创建登录
    UITapGestureRecognizer* gs=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(login)];
    [self.view addGestureRecognizer:gs];
    // Do any additional setup after loading the view, typically from a nib.
}


//登录
-(void)login{
    [[FlappyIM shareInstance] login:@"105" andSuccess:^(id data) {
        //登录成功
        NSDictionary* dic=data;
        
        
        NSString* serverIP=dic[@"serverIP"];
        NSString* serverPort=dic[@"serverPort"];
        NSString* serverTopic=dic[@"serverTopic"];
        NSString* serverGroup=dic[@"serverGroup"];
        
        
    } andFailure:^(NSError * error, NSInteger code) {
        
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
