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
    
    //初始化
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
    
    [self.sendImageBtn addTarget:self
                          action:@selector(chooseImag:)
                forControlEvents:UIControlEventTouchUpInside];
    
    [[FlappyIM shareInstance] createAccount:@"101"
                                andUserName:@"老板"
                                andUserHead:@""
                                 andSuccess:^(id _Nullable data) {
                                     
                                     NSLog(@"账户创建成功");
                                     
                                 } andFailure:^(NSError * _Nullable error, NSInteger code) {
                                     
                                 }];
    
    //踢下线
    [[FlappyIM shareInstance] setKnickedListener:^{
        NSLog(@"当前设备已经被踢下线了");
    }];
    
}

-(void)chooseImag:(id)sender{
    
    UIImagePickerController *imagePickVC = [[UIImagePickerController alloc] init];
    imagePickVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickVC.allowsEditing = NO;
    imagePickVC.delegate = self;
    imagePickVC.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
    [self presentViewController:imagePickVC animated:YES completion:nil];
}


//创建session
-(void)createSession{
    //创建session
    __weak typeof(self) safeSelf=self;
    [[FlappyIM shareInstance] createSession:@"100"
                                 andSuccess:^(id _Nullable data) {
                                     NSLog(@"会话创建成功");
                                     safeSelf.session=data;
                                     [self sessionSuccess:data];
                                     
                                 } andFailure:^(NSError * _Nullable error, NSInteger code) {
                                     NSLog(@"会话创建失败");
                                 }];
}

-(void)sessionSuccess:(FlappySession*)session{
    __weak typeof(self) safeSelf=self;
    [session addMessageListener:^(ChatMessage * _Nullable message) {
        safeSelf.lable.text=message.messageContent;
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
    if(self.session!=nil){
        [self.session sendText:self.sendText.text
                    andSuccess:^(id _Nullable data) {
                        NSLog(@"发送成功");
                    } andFailure:^(NSError * _Nullable error, NSInteger code) {
                        NSLog(@"发送失败");
                    }];
    }
}

//内存不足
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



#pragma UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
   
    
    // 本地沙盒目录
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 得到本地沙盒中名为"MyImage"的路径，"MyImage"是保存的图片名
    NSString *imageFilePath = [path stringByAppendingPathComponent:@"MyImage.png"];
    // 将取得的图片写入本地的沙盒中，其中0.5表示压缩比例，1表示不压缩，数值越小压缩比例越大
    if(self.session!=nil){
        [self.session sendLocalVoice:imageFilePath
                          andSuccess:^(id _Nullable data) {
                              NSLog(@"发送成功");
                          } andFailure:^(NSError * _Nullable error, NSInteger code) {
                              NSLog(@"发送失败");
                          }];
    }
    
    
    
}



@end
