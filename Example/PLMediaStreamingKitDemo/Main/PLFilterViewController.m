//
//  PLFilterViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/26.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import "PLFilterViewController.h"

@interface PLFilterViewController ()
@property (nonatomic, strong) NSMutableDictionary *filterDictionary;
@end

@implementation PLFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    _filterDictionary = [NSMutableDictionary dictionaryWithDictionary:_beautyDictionary];
    
    if (_imageStream) {
        /// 图片推流状态 不可操作视频
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"目前处于图片推流中，不可以修改美颜的相关属性～，请切换至视频推流后，再修改！" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertVc animated:YES completion:^{
            [self performSelector:@selector(dismissView) withObject:nil afterDelay:3];
        }];
        return;
    }
    
    [self layoutFilterTitleAndColseButton];
    [self layoutBeautySettings];
}

# pragma mark ---- 标题 ----
- (void)layoutFilterTitleAndColseButton {
    UILabel *titleLab = [[UILabel alloc]init];
    titleLab.font = FONT_MEDIUM(16);
    titleLab.text = @"美颜设置";
    [self.view addSubview:titleLab];
    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(80, 30));
        make.leftMargin.mas_equalTo(KSCREEN_WIDTH/2 - 40);
        make.topMargin.mas_equalTo(34);
    }];
    
    UIButton *closeButton = [[UIButton alloc]init];
    closeButton.layer.cornerRadius = 19;
    [closeButton addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchDown];
    [closeButton setImage:[UIImage imageNamed:@"pl_close"] forState:UIControlStateNormal];
    [self.view addSubview:closeButton];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(34, 34));
        make.leftMargin.mas_equalTo(8);
        make.topMargin.mas_equalTo(32);
    }];
}

# pragma mark ---- 美颜设置 ----
- (void)layoutBeautySettings {
    // 美颜／美白／红润
    NSArray *titleArr = @[@"setBeautify - 美颜",@"setWhiten - 美白",@"setRedden - 红润"];
    for (NSInteger i = 0; i < 3; i++) {
        
        UILabel *hintLab = [[UILabel alloc]initWithFrame:CGRectMake(20, 80 + 90 * i, 140, 30)];
        hintLab.font = FONT_MEDIUM(14.f);
        hintLab.textColor = [UIColor blackColor];
        hintLab.textAlignment = NSTextAlignmentLeft;
        hintLab.text = titleArr[i];
        [self.view addSubview:hintLab];
        
        UISlider *slider = [[UISlider alloc]initWithFrame:CGRectMake(25, 80 + 90 * i + 45, KSCREEN_WIDTH - 50, 30)];
        slider.tag = 100 + i;
        slider.minimumTrackTintColor = COLOR_RGB(147, 185, 242, 1);
        slider.maximumTrackTintColor = LINE_COLOR;
        
        slider.userInteractionEnabled = !_imageStream;
        
        UIImage *thumbImage = [UIImage imageNamed:@"thumb_slider"];
        [slider setThumbImage:thumbImage forState:UIControlStateHighlighted];
        [slider setThumbImage:thumbImage forState:UIControlStateNormal];
        slider.minimumValue = 0;
        slider.maximumValue = 1;
        slider.continuous = NO;
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:slider];
        
        switch (i) {
            case 0:
                slider.value = [_filterDictionary[@"beauty"] floatValue];
                break;
            case 1:
                slider.value = [_filterDictionary[@"whiten"] floatValue];
                break;
            case 2:
                slider.value = [_filterDictionary[@"readden"] floatValue];
                break;
            default:
                break;
        }
    }
    
    UILabel *configLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 80 + 270, 200, 30)];
    configLabel.numberOfLines = 0;
    configLabel.textColor = [UIColor blackColor];
    configLabel.textAlignment = NSTextAlignmentLeft;
    configLabel.font = FONT_MEDIUM(14.f);
    configLabel.text = @"customVideoProcess - 滤镜";
    [self.view addSubview:configLabel];
    
    UISegmentedControl *segmentControl = [[UISegmentedControl alloc]initWithItems:@[@"NO", @"YES"]];
    segmentControl.frame = CGRectMake(25, 80 + 315, KSCREEN_WIDTH - 50, 30);
    segmentControl.backgroundColor = [UIColor whiteColor];
    segmentControl.tintColor = COLOR_RGB(16, 169, 235, 1);
    [segmentControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segmentControl];
    
    segmentControl.userInteractionEnabled = !_imageStream;
    
    if (_needProcessVideo) {
        segmentControl.selectedSegmentIndex = 1;
    } else{
        segmentControl.selectedSegmentIndex = 0;
    }
}

# pragma mark ---- 分栏事件 控制滤镜 ----
- (void)segmentAction:(UISegmentedControl *)segment {
    if (segment.selectedSegmentIndex == 0) {
        self.needProcessVideo = NO;
    } else{
        self.needProcessVideo = YES;
    }
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(filetrNeedPixelBufferOn:)]) {
        [self.delegate filetrNeedPixelBufferOn:_needProcessVideo];
        [self dismissView];
    }
}

#pragma mark --- 滑条事件 控制美颜值 ---
- (void)sliderAction:(UISlider *)slider {
    NSInteger index = slider.tag - 100;
    if (index == 0) {
        // 美颜程度 范围 0 ~ 1
        [_filterDictionary setObject:[NSString stringWithFormat:@"%f", slider.value] forKey:@"beauty"];
    }
    if (index == 1) {
        // 美白程度 范围 0 ~ 1
        [_filterDictionary setObject:[NSString stringWithFormat:@"%f", slider.value] forKey:@"whiten"];
    }
    if (index == 2) {
        // 红润程度 范围 0 ~ 1
        [_filterDictionary setObject:[NSString stringWithFormat:@"%f", slider.value] forKey:@"readden"];
    }
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(filterChangeBeautyDic:)]) {
        [self.delegate filterChangeBeautyDic:[_filterDictionary copy]];
        [self dismissView];
    }
}

- (void)dismissView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
