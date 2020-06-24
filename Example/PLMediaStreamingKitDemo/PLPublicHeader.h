//
//  PLPublicHeader.h
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2020/6/15.
//  Copyright © 2020 0dayZh. All rights reserved.
//

#ifndef PLPublicHeader_h
#define PLPublicHeader_h

// 屏幕宽、高
#define KSCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define KSCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define PLTABLE_VIEW_WIDTH KSCREEN_WIDTH - 40

// 颜色值
#define COLOR_RGB(a,b,c,d) [UIColor colorWithRed:a/255.0 green:b/255.0 blue:c/255.0 alpha:d]
#define LINE_COLOR COLOR_RGB(195, 198, 198, 1)
#define BUTTON_BACKGROUNDCOLOR COLOR_RGB(54, 54, 54, 0.38)
#define SELECTED_BLUE COLOR_RGB(69, 169, 195, 1)

// 获取系统版本
#define IOS_SYSTEM_STRING [[UIDevice currentDevice] systemVersion]

// 字体 细、中
#define FONT_LIGHT(FontSize) [UIFont fontWithName:@"Avenir-Light" size:FontSize]
#define FONT_MEDIUM(FontSize) [UIFont fontWithName:@"Avenir-Medium" size:FontSize]

#define PL_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define PL_iPhoneXR ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) : NO)
#define PL_iPhoneXSMAX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)
#define PL_iPhoneP ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)

// 自定义 model
#import "PLCategoryModel.h"


// 第三方 SDK
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "Masonry.h"

// 推流 SDK
#import <PLMediaStreamingKit/PLMediaStreamingKit.h>
#define PL_MEDIA_STREAM_VERSION @"v3.0.0"

#endif /* PLPublicHeader_h */
