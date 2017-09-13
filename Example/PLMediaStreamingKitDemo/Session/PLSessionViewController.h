//
//  PLSessionViewController.h
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/26.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol PLSessionVcDelegate<NSObject>
- (void)configureSessionWithConfigureModel:(PLConfigureModel *)configureModel categoryModel:(PLCategoryModel *)categoryModel;
@end

@interface PLSessionViewController : UIViewController
@property (nonatomic, weak) id<PLSessionVcDelegate> delegate;
/// 是否是图片推流
@property (nonatomic, assign) BOOL imageStream;

@end
