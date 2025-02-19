//
//  flappyViewController.m
//  flappyim
//
//  Created by 4c641e4c592086a8d563f6d22d5a3011013286f9 on 08/06/2019.
//  Copyright (c) 2019 4c641e4c592086a8d563f6d22d5a3011013286f9. All rights reserved.
//

#import "flappyViewController.h"
#import "MJExtension.h"
#import <flappyim/FlappyIM.h>


@interface flappyViewController ()

@property(nonatomic,strong) FlappyChatSession* session;

@end

@implementation flappyViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    

    [[FlappyIM shareInstance] setPushPlat:@"Apple"];
    
    //初始化
    [[FlappyIM shareInstance] init:@"http://116.205.139.93" assetsUrl:@"http://116.205.139.93"];
    
    //开启服务
    [[FlappyIM shareInstance] startService];
    
    
    //创建登录
    [self.loginBtn addTarget:self
                      action:@selector(login:)
            forControlEvents:UIControlEventTouchUpInside];
    
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
    
    //创建账号
    //    [[FlappyIM shareInstance] createAccount:@"101" andUserName:@"李俊霖" andUserAvatar:@"waha" andSuccess:^(id data) {
    //        //登录成功
    //        NSLog(@"创建成功");
    //    } andFailure:^(NSError * error, NSInteger code) {
    //        NSLog(@"创建失败");
    //    }];
    
    [[FlappyIM shareInstance] addGloableMsgListener:[[FlappyMessageListener alloc]
                                                     initWithSend:^(ChatMessage * _Nullable message) {
        
    } andFailure:^(ChatMessage * _Nullable message) {
        
    } andReceiveList:^(NSArray * _Nullable messageList) {
        
    } andReceive:^(ChatMessage * _Nullable message) {
        
    } andDelete:^(ChatMessage * _Nullable message) {
        
    } andReadOther:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    } andReadSelf:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    }]];
    
    //会话更新
    [[FlappyIM shareInstance]  addSessionListener:[[FlappySessionListener alloc] initWithReceiveList:^(NSArray * _Nullable sessionList) {
        NSLog(@"会话有更新");
    } andReceive:^(ChatSessionData * _Nullable session) {
        NSLog(@"会话有更新");
    } andUpdateList:^(NSArray * _Nullable sessionList) {
        NSLog(@"会话有更新");
    } andUpdate:^(ChatSessionData * _Nullable session) {
        NSLog(@"会话有更新");
    } andDelete:^(ChatSessionData * _Nullable session) {
        NSLog(@"会话有更新");
    }]];
    
    //踢下线
    [[FlappyIM shareInstance] setKickedListener:^{
        NSLog(@"当前设备已经被踢下线了");
    }];
    
    //消息被点击
    [[FlappyIM shareInstance] setNotificationClickListener:^(ChatMessage * _Nullable message) {
        //打印字符串
        NSLog(@"%@", [NSString stringWithFormat:@"收到点击推送的消息:::::::%@",[message getChatText]]);
    }];
    
    [[FlappyIM shareInstance]  getUserSessionList:^(id _Nullable data) {
        NSLog(@"data");
    } andFailure:^(NSError * _Nullable err, NSInteger code) {
        NSLog(@"data");
    }];
    
}

-(void)chooseImag:(id)sender{
    
    UIImagePickerController *imagePickVC = [[UIImagePickerController alloc] init];
    imagePickVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickVC.allowsEditing = NO;
    imagePickVC.delegate = self;
    //imagePickVC.mediaTypes = [NSArray arrayWithObjects:@"public.image", nil];
    imagePickVC.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
    [self presentViewController:imagePickVC animated:YES completion:nil];
}


//创建session
-(void)createSession{
    //创建session
    __weak typeof(self) safeSelf=self;
    [[FlappyIM shareInstance] createSingleSessionByPeer:@"100"
                                       andSuccess:^(id _Nullable data) {
        NSLog(@"会话创建成功");
        safeSelf.session=data;
        [self sessionSuccess:data];
        
        ChatMessage* ms=[safeSelf.session getLatestMessage];
        safeSelf.lable.text=[ms getChatText];
        
        ChatMessage* msg=[safeSelf.session getLatestMessage];
        
        NSLog(@"%ld",(long)msg.messageTableOffset);
        
        if(msg!=nil){
            NSMutableArray* formers=[safeSelf.session getFormerMessages:msg.messageId
                                                               withSize:10];
            
            for(int s=0;s<formers.count;s++){
                ChatMessage* message=[formers objectAtIndex:s];
                
                NSLog(@"%ld",(long)message.messageTableOffset);
            }
        }
        
        
    } andFailure:^(NSError * _Nullable error, NSInteger code) {
        NSLog(@"会话创建失败");
    }];
}

-(void)sessionSuccess:(FlappyChatSession*)session{
    __weak typeof(self) safeSelf=self;
    [session addMessageListener:[[FlappyMessageListener alloc]
                                 initWithSend:^(ChatMessage * _Nullable message) {
        
    } andFailure:^(ChatMessage * _Nullable message) {
        
    } andReceiveList:^(NSArray * _Nullable messageList) {
        
    } andReceive:^(ChatMessage * _Nullable message) {
        safeSelf.lable.text=[message getChatText];
    } andDelete:^(ChatMessage * _Nullable message) {
        
    } andReadOther:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    } andReadSelf:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    }]];
}


//登录
-(void)login:(id)sender{
    [[FlappyIM shareInstance] login:@"1" andSuccess:^(id data) {
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
                    andSuccess:^(ChatMessage* _Nullable data) {
            NSLog(@"发送成功");
        } andFailure:^(ChatMessage* msg,NSError * _Nullable error, NSInteger code) {
            NSLog(@"发送失败");
        }];
        
        //        ChatLocation* loc=[[ChatLocation alloc]init];
        //        loc.lat=@"11111";
        //        loc.lng=@"222222";
        //        loc.address=@"345354354";
        //
        //        [self.session sendLocation:loc
        //                        andSuccess:^(ChatMessage* _Nullable data) {
        //            NSLog(@"发送成功");
        //        } andFailure:^(ChatMessage* msg,NSError * _Nullable error, NSInteger code) {
        //            NSLog(@"发送失败");
        //        }];
        
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
    
    //NSURL * url =[info objectForKey:UIImagePickerControllerImageURL];
    NSURL * url =[info objectForKey:UIImagePickerControllerMediaURL];
    if(self.session!=nil){
        NSString* str=[url.absoluteString substringWithRange:NSMakeRange(7, url.absoluteString.length-7)];
        
        //        [self.session sendLocalImage:str
        //                          andSuccess:^(ChatMessage* _Nullable data) {
        //            NSLog(@"发送成功");
        //        } andFailure:^(ChatMessage* msg,NSError * _Nullable error, NSInteger code) {
        //            NSLog(@"发送失败");
        //        }];
        
        [self.session sendLocalVideo:str
                          andSuccess:^(ChatMessage* _Nullable data) {
            NSLog(@"发送成功");
        } andFailure:^(ChatMessage* msg,NSError * _Nullable error, NSInteger code) {
            NSLog(@"发送失败");
        }];
    }
    
    
}



@end
