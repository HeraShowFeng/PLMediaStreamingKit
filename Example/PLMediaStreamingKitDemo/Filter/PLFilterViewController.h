//
//  PLFilterViewController.h
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/26.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol PLFilterVcDelegate <NSObject>

- (void)filterChangeBeautyDic:(NSDictionary *)dict;
- (void)filetrNeedPixelBufferOn:(BOOL)needProcessVideo;
@end

@interface PLFilterViewController : UIViewController
@property (nonatomic, assign) BOOL isBeauty;
@property (nonatomic, strong) NSDictionary *beautyDict;
@property (nonatomic, weak) id<PLFilterVcDelegate> delegate;
@property (nonatomic, assign) BOOL needProcessVideo;
/// 是否是图片推流
@property (nonatomic, assign) BOOL imageStream;

@end
