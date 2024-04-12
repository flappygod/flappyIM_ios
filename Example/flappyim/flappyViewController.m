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
    
    
    NSString * encrypt = [RSATool encryptWithPublicKey:@"-----BEGIN PUBLIC KEY-----\n"
                          "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA/EUkiEsrSMsdS3Eb8d5+\n"
                          "RuJlcCa9sQ9nImZ7glnTT9pGfyPPqW5HFcKamNsd1PRb+VFr6OK01i1neakLjHA4\n"
                          "XGBxDg6JKdAdWakk+xMib5OZnhDEin9wGNBmTLCJLreN+vJkj0Knb6D9ClLgHWkl\n"
                          "6mcQUvkU59ckr7NcG4/h9pbFWVigDrDitlpTRZBxOhUH9cOcRlu5nCc2r07hQRvk\n"
                          "ZUBCfg5Gs0liXJsUfeCigpqvKYpFTx2Iz48uRUD9bJKVHyvI3girTR32flbt0pmi\n"
                          "8k/1/Rs74+g6YD1/RC/Bc03eOXfdHQMsy1XjN94sjHNhHgLPE+1TKXjEeOpnb8Gk\n"
                          "kQIDAQAB\n"
                          "-----END PUBLIC KEY-----" withData:@"四川雅安河道现大熊猫尸体"];
    
    
    NSLog(@"%@",encrypt);
    
    
    NSString * decrypt = [RSATool decryptWithPrivateKeyPKCS1:@"-----BEGIN RSA PRIVATE KEY-----\n"
                          "MIIEpAIBAAKCAQEA/EUkiEsrSMsdS3Eb8d5+RuJlcCa9sQ9nImZ7glnTT9pGfyPP\n"
                          "qW5HFcKamNsd1PRb+VFr6OK01i1neakLjHA4XGBxDg6JKdAdWakk+xMib5OZnhDE\n"
                          "in9wGNBmTLCJLreN+vJkj0Knb6D9ClLgHWkl6mcQUvkU59ckr7NcG4/h9pbFWVig\n"
                          "DrDitlpTRZBxOhUH9cOcRlu5nCc2r07hQRvkZUBCfg5Gs0liXJsUfeCigpqvKYpF\n"
                          "Tx2Iz48uRUD9bJKVHyvI3girTR32flbt0pmi8k/1/Rs74+g6YD1/RC/Bc03eOXfd\n"
                          "HQMsy1XjN94sjHNhHgLPE+1TKXjEeOpnb8GkkQIDAQABAoIBADogwHs7Pt0GGFjy\n"
                          "1iqURuqUbiU6eAkdcHlHvfvaMMu8kvPmz4nN5ElKTw8bpjMUn0DClyfRXTPgwHAT\n"
                          "GJsinIoEmuhPRyHAV5L6W5AS56NoEkSOvorfNHgzRO802ldOakPBqJQuGqCpKsU/\n"
                          "NW7xdJAfcW59AGkvdL+bh4S+UaXcwL0jT0Zt/Qsc9vk7lnagyFYvYljFRhN9Pdwt\n"
                          "eWu6cUCrds7a2zeNGDiEAenfwgdO+0gwuSKs6Y+anXiRT6pFEw2EiDeLqu8txaYq\n"
                          "ibnmLKK40c1J07k4dXoQGu3uFovnO/xyoaJHK0ur4jFtcHaAbxj97mgwq4JdgX0G\n"
                          "24G0IFUCgYEA/xh1T+ZHc3VZVgXZAc6fqYfTlSZFO+6AEx4inV43mv0ypWVQKoSW\n"
                          "a76iGf0rRoPrL2wWJUwpr92FOwO9aEeUuHRHky4/SlQzD7rcG/74OK+RiSDyIicY\n"
                          "3gpGeLmGIK5Nj9w9rsQzryLT84KP1MfY7z9uKJcErtKWlM8zH8porQcCgYEA/Soe\n"
                          "sNet8trHsDJDgInD8cOr1fXdlXvS9Iz2iFH3i42kR5DXB3FM3Lhhd3Hha6zA++W7\n"
                          "kwtpOQGzM/GR0ZqyiVX7ujQEq6rw43nRYYrwl1sugaRXmeF9/mSedzl1scGQRM7v\n"
                          "LoSaKlszdydRZWpvQa7kinJHOaO++nChhU9E06cCgYEA8d6D5LUoDC44/VpgDtmW\n"
                          "A0047VMzFAcoQngxQ9rAiGEIc1AjeZzrbs96rX+hV6PfC8DFIqobYJd+Kp16KnSs\n"
                          "a1Q9RSz1b4l0PLbk2lqfikfVixrE2mMNrgI6HV9y8Gu0OPIPPjTj+GviYSHrNEok\n"
                          "w3v1++Bs3UHo6sGm7L6jD2MCgYBWXgY2Yn4veb/iNmOc+GLmmdCHn+dGVgXz9Bsv\n"
                          "CnefHmVLHPiey2Jjcmud6jXzG+6CgS9qzNvK3O+b6u/KSDJcc/762UA2qIyhri9m\n"
                          "TZYirLLC+6P/FVR8cys0lV+3ksd7EfW7MvW9OXvnTHySUqs+B0JkkPQHj/tZSQ9x\n"
                          "gUeDxQKBgQDPZt/fjAmtW8uJEzrd0Wk11tfYQynh0kOYzcccU8IuWncYqqBbxnFc\n"
                          "J9OvW96SmrPFIa/z8MYeKU2LnBf5w76MPcZbtpZmvwypwkouF+ishxfpCM7vZ+nv\n"
                          "MFag3D6PCFBtUm0oUIA5WOmELt6s1ovIL/IFYmp10E62G/EbclHp3g==\n"
                          "-----END RSA PRIVATE KEY-----"
                                               withData:@"DbcZd8V870MimyU68pviq35JzQ4zQIOpHfwFENL/R/yw4hM+U3Tf6cnpE6KWdJ7NRwPpH5hjTJ21MRkD3V9OImGKdlT3GEGUQtYR1MS++tMvkB81kA2LRw55Z6OdvOMiJ58JBv2Cvx+uV2Vr84bspnme0q1cObnJx/iOLaX8t83OZ+5v/aad646n++5Ti62rTAkmxtnO+1Ui5FgeFs3psx/6PcuZ+13sO7plZNYlO33cslRkoNK/cpd/h4iwLfriAwOS+DWmf2rzPii11EDNQBjuehmBlEXseBqYi3YgjVRtmtdTSdupt38g0PS1MMNAKKv99W5Okf0uAVFn7hGjlw=="];
    
    
    NSLog(@"%@",decrypt);
    
    
    
    [[FlappyIM shareInstance] setPushPlatfrom:@"Apple"];
    
    //初始化
    [[FlappyIM shareInstance] setup:@"http://116.205.139.93" withUploadUrl:@"http://116.205.139.93"];
    
    
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
        
    } andUpdate:^(ChatMessage * _Nullable message) {
        
    } andReceive:^(ChatMessage * _Nullable message) {
        
    } andReadOther:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    } andReadSelf:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    } andDelete:^(NSString * _Nullable messageId) {
        
    }]];
    
    //会话更新
    [[FlappyIM shareInstance]  addSessionListener:^(FlappyChatSession*  _Nullable chatsession) {
        NSLog(@"会话有更新");
    }];
    
    //踢下线
    [[FlappyIM shareInstance] setKnickedListener:^{
        NSLog(@"当前设备已经被踢下线了");
    }];
    
    //消息被点击
    [[FlappyIM shareInstance] setNotifyClickListener:^(ChatMessage * _Nullable message) {
        //打印字符串
        NSLog(@"%@", [NSString stringWithFormat:@"收到点击推送的消息:::::::%@",[message getChatText]]);
    }];
    
    [[FlappyIM shareInstance]  getUserSessions:^(id _Nullable data) {
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
    [[FlappyIM shareInstance] createSingleSession:@"100"
                                       andSuccess:^(id _Nullable data) {
        NSLog(@"会话创建成功");
        safeSelf.session=data;
        [self sessionSuccess:data];
        
        ChatMessage* ms=[safeSelf.session getLatestMessage];
        safeSelf.lable.text=[ms getChatText];
        
        ChatMessage* msg=[safeSelf.session getLatestMessage];
        
        NSLog(@"%ld",(long)msg.messageTableSeq);
        
        if(msg!=nil){
            NSMutableArray* formers=[safeSelf.session getFormerMessages:msg.messageId
                                                               withSize:10];
            
            for(int s=0;s<formers.count;s++){
                ChatMessage* message=[formers objectAtIndex:s];
                
                NSLog(@"%ld",(long)message.messageTableSeq);
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
        
    } andUpdate:^(ChatMessage * _Nullable message) {
        
    } andReceive:^(ChatMessage * _Nullable message) {
        safeSelf.lable.text=[message getChatText];
    } andReadOther:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    } andReadSelf:^(NSString * _Nullable sessionId, NSString * _Nullable readerId, NSString * _Nullable tableSeqence) {
        
    } andDelete:^(NSString * _Nullable messageId) {
        
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
