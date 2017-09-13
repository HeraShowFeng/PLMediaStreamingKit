//
//  PLPublicHeader.h
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/23.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#ifndef PLPublicHeader_h
#define PLPublicHeader_h

/// 屏幕宽、高
#define KSCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define KSCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

/// 颜色值
#define COLOR_RGB(a,b,c,d) [UIColor colorWithRed:a/255.0 green:b/255.0 blue:c/255.0 alpha:d]
#define LINE_COLOR COLOR_RGB(195, 198, 198, 1)
#define BUTTON_BACKGROUNDCOLOR COLOR_RGB(54, 54, 54, 0.32)
#define SELECTED_BLUE COLOR_RGB(69, 169, 195, 1)

/// 字体 细、中
#define FONT_LIGHT(FontSize) [UIFont fontWithName:@"Avenir-Light" size:FontSize]
#define FONT_MEDIUM(FontSize) [UIFont fontWithName:@"Avenir-Medium" size:FontSize]

/// 获取系统版本
#define IOS_SYSTEM_STRING [[UIDevice currentDevice] systemVersion]


#import "PLListArrayView.h"
#import "PLCategoryModel.h"


# warning PLMediaStreamingKit 推流核心类
#import "PLMediaStreamingKit.h"

/// 第三方

/// 轻量级布局框架
#import <Masonry/Masonry.h>
/// 记录Crash日志
#import <Fabric/Fabric.h>
/// 奔溃统计工具
#import <Crashlytics/Crashlytics.h>




#endif /* PLPublicHeader_h */
