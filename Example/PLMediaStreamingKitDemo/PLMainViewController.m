//
//  PLMainViewController.m
//  PLCameraStreamingKitDemo
//
//  Created by TaoZeyu on 16/5/27.
//  Copyright © 2016年 Pili. All rights reserved.
//

#import "PLMainViewController.h"

#import "PLMediaViewController.h"

#define kLogoSizeWidth (KSCREEN_WIDTH - 100)
#define kLogoSizeHeight (KSCREEN_WIDTH - 100)*0.38

@interface PLMainViewController ()

@end

@implementation PLMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *qiniuLogImgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"LOGO"]];
    qiniuLogImgView.frame = CGRectMake(50, (KSCREEN_HEIGHT - kLogoSizeHeight - 116)/3, kLogoSizeWidth, kLogoSizeHeight);
    [self.view addSubview:qiniuLogImgView];
    
    UIButton *enterButton = [[UIButton alloc] initWithFrame:CGRectMake(70, (KSCREEN_HEIGHT - kLogoSizeHeight - 116)/3 + kLogoSizeHeight + 50, KSCREEN_WIDTH - 140, 34)];
    enterButton.backgroundColor = BUTTON_BACKGROUNDCOLOR;
    enterButton.layer.cornerRadius = 3;
    [enterButton addTarget:self action:@selector(enterMediaStreamingAction:) forControlEvents:UIControlEventTouchDown];
    [enterButton setTitle:@"进入MediaStreaming" forState:UIControlStateNormal];
    enterButton.titleLabel.font = FONT_MEDIUM(14);
    [self.view addSubview:enterButton];
   
}

- (void)enterMediaStreamingAction:(UIButton *)button
{
    PLMediaViewController *mainVC = [[PLMediaViewController alloc] init];
    [self presentViewController:mainVC animated:NO completion:nil];
}


@end
