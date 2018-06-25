//
//  PLConfigurationViewController.h
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/26.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol PLConfigurationVcDelegate<NSObject>
- (void)configureStreamWithConfigureModel:(PLConfigureModel *)configureModel categoryModel:(PLCategoryModel *)categoryModel isSession:(BOOL)isSession;
@end

@interface PLConfigurationViewController : UIViewController

@property (nonatomic, weak) id<PLConfigurationVcDelegate> delegate;
/// 是否是图片推流
@property (nonatomic, assign) BOOL imageStream;
/// 是否session
@property (nonatomic, assign) BOOL isSession;
@end
