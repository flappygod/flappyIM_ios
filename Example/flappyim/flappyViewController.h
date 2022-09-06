//
//  flappyViewController.h
//  flappyim
//
//  Created by 4c641e4c592086a8d563f6d22d5a3011013286f9 on 08/06/2019.
//  Copyright (c) 2019 4c641e4c592086a8d563f6d22d5a3011013286f9. All rights reserved.
//

@import UIKit;

@interface flappyViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

//当前的lable
@property (weak, nonatomic) IBOutlet UITextField *sendText;
@property (weak, nonatomic) IBOutlet UILabel *lable;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UIButton *create;
@property (weak, nonatomic) IBOutlet UIButton *sendImageBtn;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end
