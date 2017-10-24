//
//  PLListArrTableViewCell.h
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/27.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLListArrTableViewCell : UITableViewCell
@property (nonatomic, strong) UILabel *configLabel;
@property (nonatomic, strong) UIButton *listButton;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, assign) NSInteger index;


- (void)confugureListArrayCellWithConfigureModel:(PLConfigureModel *)configureModel;
+ (CGFloat)configureListArrayCellHeightWithString:(NSString *)string;
@end
