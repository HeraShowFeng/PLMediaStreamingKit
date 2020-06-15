//
//  PLShowDetailView.m
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2020/6/10.
//  Copyright © 2020 Pili. All rights reserved.
//

#import "PLShowDetailView.h"
#import "PLPasterScrollView.h"

#define PL_X_SPACE 16
#define PL_Y_SPACE 12

@interface PLShowDetailView()
<
PLPasterScrollViewDelegate,
PLPasterViewDelegate
>

@property (nonatomic, assign) PLSetDetailViewType type;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, strong) UISegmentedControl *orientaionSegmentControl;
@property (nonatomic, strong) UISegmentedControl *imgPushSegmentControl;
@property (nonatomic, strong) UISegmentedControl *watermarkSegmentControl;
@property (nonatomic, strong) UISegmentedControl *audioEffectSegmentControl;

@property (nonatomic, strong) UIView *beautySetView;
@property (nonatomic, strong) NSMutableArray *beautySliderArray;
@property (nonatomic, strong) UISegmentedControl *beautyModeSegmentControl;

@property (nonatomic, strong) UIView *stickerSetView;
@property (nonatomic, strong) PLPasterScrollView *pasterScrollView;
@property (nonatomic, strong) PLPasterView *pasterView;
@property (nonatomic, strong) NSMutableArray *stickerImageArray;

@property (nonatomic, strong) UIView *audioMixSetView;
@property (nonatomic, copy) NSString *musicFileString;
@property (nonatomic, strong) UIButton *playbutton;
@property (nonatomic, strong) UIButton *playBackbutton;
@property (nonatomic, strong) UISlider *volumeSlider;

@end

@implementation PLShowDetailView

- (id)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        self.backgroundColor = COLOR_RGB(0, 0, 0, 0.5);
        
        _width = CGRectGetWidth(frame);
        _height = CGRectGetWidth(frame);
        
        // 旋转方向 view
        [self layoutOrientaionView];
        
        // 图片推流设置 view
        [self layoutImagePushView];
        
        // 水印设置 view
        [self layoutWatermarkView];
        
        // 混音设置 view
        [self layoutAudioMixView];
        
        // 美颜设置 view
        [self layoutBeautyView];
        
        // 贴纸设置 view
        [self layoutStickerView];
                
        // 音效设置 view
        [self layoutAudioEffectView];
    }
    return self;
}

#pragma mark - 旋转方向
- (void)layoutOrientaionView {
    _orientaionSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Portrait", @"UpsideDown", @"Right", @"Left"]];
    _orientaionSegmentControl.frame = CGRectMake(PL_X_SPACE, PL_Y_SPACE, _width - PL_X_SPACE*2, 30);
    _orientaionSegmentControl.tintColor = COLOR_RGB(16, 169, 235, 1);
    _orientaionSegmentControl.selectedSegmentIndex = 0;
    _orientaionSegmentControl.hidden = YES;
    [_orientaionSegmentControl addTarget:self action:@selector(selectedSegmentedControl:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_orientaionSegmentControl];
}

#pragma mark - 图片推流
- (void)layoutImagePushView {
    _imgPushSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"nil", @"七牛", @"leave"]];
    _imgPushSegmentControl.frame = CGRectMake(PL_X_SPACE, PL_Y_SPACE, _width - PL_X_SPACE*2, 30);
    _imgPushSegmentControl.tintColor = COLOR_RGB(16, 169, 235, 1);
    _imgPushSegmentControl.selectedSegmentIndex = 0;
    _imgPushSegmentControl.hidden = YES;
    [_imgPushSegmentControl addTarget:self action:@selector(selectedSegmentedControl:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_imgPushSegmentControl];
}

#pragma mark - 水印
- (void)layoutWatermarkView {
    _watermarkSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"nil", @"七牛", @"小七1", @"小七2"]];
    _watermarkSegmentControl.frame = CGRectMake(PL_X_SPACE, PL_Y_SPACE, _width - PL_X_SPACE*2, 30);
    _watermarkSegmentControl.tintColor = COLOR_RGB(16, 169, 235, 1);
    _watermarkSegmentControl.selectedSegmentIndex = 0;
    _watermarkSegmentControl.hidden = YES;
    [_watermarkSegmentControl addTarget:self action:@selector(selectedSegmentedControl:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_watermarkSegmentControl];
}

#pragma mark - 音效
- (void)layoutAudioEffectView {
    _audioEffectSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"none", @"Low", @"Medium", @"Height"]];
    _audioEffectSegmentControl.frame = CGRectMake(PL_X_SPACE, PL_Y_SPACE, _width - PL_X_SPACE*2, 30);
    _audioEffectSegmentControl.tintColor = COLOR_RGB(16, 169, 235, 1);
    _audioEffectSegmentControl.selectedSegmentIndex = 0;
    _audioEffectSegmentControl.hidden = YES;
    [_audioEffectSegmentControl addTarget:self action:@selector(selectedSegmentedControl:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_audioEffectSegmentControl];
}

// 分栏选择
- (void)selectedSegmentedControl:(UISegmentedControl *)segmentControl {
    if(self.delegate && [self.delegate respondsToSelector:@selector(showDetailView:didClickIndex:currentType:)]) {
        [self.delegate showDetailView:self didClickIndex:segmentControl.selectedSegmentIndex currentType:_type];
    }
}

#pragma mark - 美颜
- (void)layoutBeautyView {
    _beautySetView = [[UIView alloc] initWithFrame:CGRectMake(PL_X_SPACE, PL_Y_SPACE, _width - PL_X_SPACE*2, 128)];
    _beautySetView.hidden = YES;
    [self addSubview:_beautySetView];
    
    UILabel *configLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 78, 26)];
    configLabel.numberOfLines = 0;
    configLabel.textColor = [UIColor whiteColor];
    configLabel.textAlignment = NSTextAlignmentLeft;
    configLabel.font = FONT_LIGHT(12.f);
    configLabel.text = @"beautyMode:";
    [_beautySetView addSubview:configLabel];
    
    _beautyModeSegmentControl = [[UISegmentedControl alloc]initWithItems:@[@"NO", @"YES"]];
    _beautyModeSegmentControl.frame = CGRectMake(82, 0, _width - 82 - PL_X_SPACE*2, 26);
    _beautyModeSegmentControl.tintColor = COLOR_RGB(16, 169, 235, 1);
    [_beautyModeSegmentControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    [_beautySetView addSubview:_beautyModeSegmentControl];
    _beautyModeSegmentControl.selectedSegmentIndex = 1;

    
    _beautySliderArray = [NSMutableArray array];
    
    // 美颜／美白／红润
    NSArray *titleArr = @[@"setBeautify:",@"setWhiten:",@"setRedden:"];
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *hintLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 33 * (i + 1), 68, 26)];
        hintLab.font = FONT_LIGHT(12.f);
        hintLab.textColor = [UIColor whiteColor];
        hintLab.textAlignment = NSTextAlignmentLeft;
        hintLab.text = titleArr[i];
        [_beautySetView addSubview:hintLab];
        
        UISlider *slider = [[UISlider alloc]initWithFrame:CGRectMake(72, 33 * (i + 1), _width - 72 - PL_X_SPACE*2, 26)];
        slider.tag = 100 + i;
        slider.minimumTrackTintColor = COLOR_RGB(147, 185, 242, 1);
        slider.maximumTrackTintColor = LINE_COLOR;
                
        slider.minimumValue = 0;
        slider.maximumValue = 1;
        slider.continuous = NO;
        slider.value = 0.5;
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [_beautySetView addSubview:slider];
        
        [_beautySliderArray addObject:slider];
    }
}

// 滑条事件 控制美颜值
- (void)sliderAction:(UISlider *)slider {
    NSInteger index = slider.tag - 100;
    [_beautySliderArray replaceObjectAtIndex:index withObject:slider];
    
    CGFloat beauty = 0;
    CGFloat white = 0;
    CGFloat red = 0;
    for (NSInteger i = 0; i < _beautySliderArray.count; i++) {
        UISlider *slider = _beautySliderArray[i];
        if (i == 0) {
            beauty = slider.value;
        } else if (i == 1) {
            white = slider.value;
        } else if (i == 2) {
            red = slider.value;
        }
    }

    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(showDetailView:didChangeBeautyMode:beauty:white:red:)]) {
        [self.delegate showDetailView:self didChangeBeautyMode:_beautyModeSegmentControl.selectedSegmentIndex beauty:beauty white:white red:red];
    }
}

// 分栏事件 控制开关
- (void)segmentAction:(UISegmentedControl *)segment {
    CGFloat beauty = 0;
    CGFloat white = 0;
    CGFloat red = 0;
    for (NSInteger i = 0; i < _beautySliderArray.count; i++) {
        UISlider *slider = _beautySliderArray[i];
        if (i == 0) {
            beauty = slider.value;
        } else if (i == 1) {
            white = slider.value;
        } else if (i == 2) {
            red = slider.value;
        }
    }

    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(showDetailView:didChangeBeautyMode:beauty:white:red:)]) {
        [self.delegate showDetailView:self didChangeBeautyMode:_beautyModeSegmentControl.selectedSegmentIndex beauty:beauty white:white red:red];
    }
}

#pragma mark - 贴纸
- (void)layoutStickerView {
    _stickerSetView = [[UIView alloc] initWithFrame:CGRectMake(PL_X_SPACE, PL_Y_SPACE, _width - PL_X_SPACE*2, 80)];
    _stickerSetView.hidden = YES;
    [self addSubview:_stickerSetView];
    
    _stickerImageArray = [NSMutableArray array];
    for (int i = 1; i <= 9; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"00%d", i]];
        [_stickerImageArray addObject:image];
    }
    
    _pasterScrollView = [[PLPasterScrollView alloc] initScrollViewWithPasterImageArray:_stickerImageArray];
    _pasterScrollView.frame = CGRectMake(0, 0, _width - PL_X_SPACE*2, 80);
    _pasterScrollView.showsHorizontalScrollIndicator = YES;
    _pasterScrollView.showsVerticalScrollIndicator = NO;
    _pasterScrollView.bounces = YES;
    _pasterScrollView.contentSize = CGSizeMake(_pasterScrollView.pasterImage_W_H * _pasterScrollView.pasterImageArray.count + 15 * (_pasterScrollView.pasterImageArray.count + 1), 0);
    _pasterScrollView.pasterDelegate = self;
    [_stickerSetView addSubview:_pasterScrollView];
}

#pragma mark - PLPasterScrollViewDelegate
- (void)pasterScrollView:(PLPasterScrollView *)pasterScrollView pasterTag:(NSInteger)pasterTag pasterImage:(UIImage *)pasterImage {
    PLPasterView *pasterView = [[PLPasterView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
    pasterView.center = CGPointMake(KSCREEN_WIDTH / 2, KSCREEN_HEIGHT / 2);
    pasterView.pasterImage = pasterImage;
    pasterView.delegate = self;
    
    _pasterView = pasterView;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(showDetailView:didAddStickerView:)]) {
        [self.delegate showDetailView:self didAddStickerView:_pasterView];
    }
}

#pragma mark - PLPasterViewDelegate
- (void)deletePasterView:(PLPasterView *)pasterView {
    _pasterScrollView.defaultButton.selected = NO;
    _pasterScrollView.defaultButton.layer.borderColor = [UIColor clearColor].CGColor;
    _pasterScrollView.defaultButton.layer.borderWidth = 0.1;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(showDetailView:didRemoveStickerView:)]) {
        [self.delegate showDetailView:self didRemoveStickerView:pasterView];
    }
    _pasterView = nil;
}

- (void)endDragPasterView:(PLPasterView *)pasterView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showDetailView:didRefreshStickerView:)]) {
        [self.delegate showDetailView:self didRefreshStickerView:pasterView];
    }
}

#pragma mark - 混音
- (void)layoutAudioMixView {
    _audioMixSetView = [[UIView alloc] initWithFrame:CGRectMake(PL_X_SPACE, PL_Y_SPACE, _width - PL_X_SPACE*2, 142)];
    _audioMixSetView.hidden = YES;
    [self addSubview:_audioMixSetView];
    
    _playbutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _width/2 - PL_X_SPACE - 5, 28)];
    [_playbutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _playbutton.layer.borderColor = [UIColor whiteColor].CGColor;
    _playbutton.layer.borderWidth = 0.5f;
    _playbutton.titleLabel.font = FONT_LIGHT(12.f);
    [_playbutton setTitle:@"播放" forState:UIControlStateNormal];
    [_playbutton setTitle:@"暂停" forState:UIControlStateSelected];
    [_playbutton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchDown];
    [_audioMixSetView addSubview:_playbutton];
    
    _playBackbutton = [[UIButton alloc] initWithFrame:CGRectMake(_width/2 - PL_X_SPACE + 5, 0, _width/2 - PL_X_SPACE - 5, 28)];
    [_playBackbutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _playBackbutton.layer.borderColor = [UIColor whiteColor].CGColor;
    _playBackbutton.layer.borderWidth = 0.5f;
    _playBackbutton.titleLabel.font = FONT_LIGHT(12.f);
    [_playBackbutton setTitle:@"打开返听" forState:UIControlStateNormal];
    [_playBackbutton setTitle:@"关闭返听" forState:UIControlStateSelected];
    [_playBackbutton addTarget:self action:@selector(playBackAction:) forControlEvents:UIControlEventTouchDown];
    [_audioMixSetView addSubview:_playBackbutton];
    
    UILabel *configLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 42, 74, 26)];
    configLabel.numberOfLines = 0;
    configLabel.textColor = [UIColor whiteColor];
    configLabel.textAlignment = NSTextAlignmentLeft;
    configLabel.font = FONT_LIGHT(12.f);
    configLabel.text = @"Music File：";
    [_audioMixSetView addSubview:configLabel];
    
    _beautyModeSegmentControl = [[UISegmentedControl alloc]initWithItems:@[@"M1", @"M2", @"M3", @"M4", @"M5"]];
    _beautyModeSegmentControl.frame = CGRectMake(78, 42, _width - 78 - PL_X_SPACE*2, 26);
    _beautyModeSegmentControl.tintColor = COLOR_RGB(16, 169, 235, 1);
    [_beautyModeSegmentControl addTarget:self action:@selector(musicSegmentAction:) forControlEvents:UIControlEventValueChanged];
    [_audioMixSetView addSubview:_beautyModeSegmentControl];
    _beautyModeSegmentControl.selectedSegmentIndex = 0;
        
    UILabel *volumeHintLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 78, 68, 26)];
    volumeHintLab.font = FONT_LIGHT(12.f);
    volumeHintLab.textColor = [UIColor whiteColor];
    volumeHintLab.textAlignment = NSTextAlignmentLeft;
    volumeHintLab.text = @"volume：";
    [_audioMixSetView addSubview:volumeHintLab];
    
    _volumeSlider = [[UISlider alloc]initWithFrame:CGRectMake(72, 78, _width - 72 - PL_X_SPACE*2, 26)];
    _volumeSlider.minimumTrackTintColor = COLOR_RGB(147, 185, 242, 1);
    _volumeSlider.maximumTrackTintColor = LINE_COLOR;
    _volumeSlider.minimumValue = 0;
    _volumeSlider.maximumValue = 1;
    _volumeSlider.value = 0.5;
    _volumeSlider.continuous = NO;
    [_volumeSlider addTarget:self action:@selector(volumeSliderAction:) forControlEvents:UIControlEventValueChanged];
    [_audioMixSetView addSubview:_volumeSlider];
    
    UILabel *progressHintLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 115, 68, 26)];
    progressHintLab.font = FONT_LIGHT(12.f);
    progressHintLab.textColor = [UIColor whiteColor];
    progressHintLab.textAlignment = NSTextAlignmentLeft;
    progressHintLab.text = @"progress：";
    [_audioMixSetView addSubview:progressHintLab];
    
    _progressSlider = [[UISlider alloc]initWithFrame:CGRectMake(72, 115, _width - 72 - PL_X_SPACE*2, 26)];
    _progressSlider.minimumTrackTintColor = COLOR_RGB(147, 185, 242, 1);
    _progressSlider.maximumTrackTintColor = LINE_COLOR;
    _progressSlider.minimumValue = 0;
    _progressSlider.maximumValue = 1;
    _progressSlider.continuous = NO;
    [_progressSlider addTarget:self action:@selector(progressSliderAction:) forControlEvents:UIControlEventValueChanged];
    [_audioMixSetView addSubview:_progressSlider];
    
    _musicFileString = [[NSBundle mainBundle] pathForResource:@"TestMusic1" ofType:@"m4a"];
}

- (void)musicSegmentAction:(UISegmentedControl *)segmentControl {
    NSArray *fileArray = @[[[NSBundle mainBundle] pathForResource:@"TestMusic1" ofType:@"m4a"],
                           [[NSBundle mainBundle] pathForResource:@"TestMusic2" ofType:@"wav"],
                           [[NSBundle mainBundle] pathForResource:@"TestMusic3" ofType:@"mp3"],
                           [[NSBundle mainBundle] pathForResource:@"TestMusic4" ofType:@"mp3"],
                           [[NSBundle mainBundle] pathForResource:@"TestMusic5" ofType:@"mp3"]];
    _musicFileString = fileArray[segmentControl.selectedSegmentIndex];
    [self delegateUpdateStateAudioPlayer];
}

- (void)playAction:(UIButton *)button {
    button.selected = !button.selected;
    [self delegateUpdateStateAudioPlayer];
}

- (void)playBackAction:(UIButton *)button {
    button.selected = !button.selected;
    [self delegateUpdateStateAudioPlayer];
}

- (void)volumeSliderAction:(UISlider *)slider {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showDetailView:didUpdateAudioPlayVolume:)]) {
        [self.delegate showDetailView:self didUpdateAudioPlayVolume:slider.value];
    }
}

- (void)progressSliderAction:(UISlider *)slider {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showDetailView:didUpdateAudioPlayProgress:)]) {
        [self.delegate showDetailView:self didUpdateAudioPlayProgress:slider.value];
    }\
}

- (void)delegateUpdateStateAudioPlayer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showDetailView:didUpdateAudioPlayer:playBack:file:)]) {
        [self.delegate showDetailView:self didUpdateAudioPlayer:_playbutton.selected playBack:_playBackbutton.selected file:_musicFileString];
    }
}

#pragma mark - 显示细节配置视图
- (void)showDetailSettingViewWithType:(PLSetDetailViewType)type {
    _type = type;
    [self hideDetailSettingView];
    switch (type) {
        case PLSetDetailViewOrientaion:
            _orientaionSegmentControl.hidden = NO;
            _height = 30 + PL_Y_SPACE * 2;
            break;
            
        case PLSetDetailViewBeauty:
            _beautySetView.hidden = NO;
            _height = 128 + PL_Y_SPACE * 2;;
            break;
            
        case PLSetDetailViewImagePush:
            _imgPushSegmentControl.hidden = NO;
            _height = 30 + PL_Y_SPACE * 2;

            break;
            
        case PLSetDetailViewSticker:
            _stickerSetView.hidden = NO;
            _height = 80 + PL_Y_SPACE * 2;;
            break;
            
        case PLSetDetailViewWaterMark:
            _watermarkSegmentControl.hidden = NO;
            _height = 30 + PL_Y_SPACE * 2;

            break;
        case PLSetDetailViewAudioMix:
            _audioMixSetView.hidden = NO;
            _height = 142 + PL_Y_SPACE * 2;
            break;
            
        case PLSetDetailViewAudioEffect:
            _audioEffectSegmentControl.hidden = NO;
            _height = 30 + PL_Y_SPACE * 2;

            break;

        default:
            break;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(0, KSCREEN_HEIGHT - _height, _width, _height);
    }];
}

#pragma mark - 隐藏细节配置视图
- (void)hideDetailSettingView {
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(0, KSCREEN_HEIGHT, _width, self.frame.size.height);
    }];
    _orientaionSegmentControl.hidden = YES;
    _imgPushSegmentControl.hidden = YES;
    _watermarkSegmentControl.hidden = YES;
    _audioEffectSegmentControl.hidden = YES;

    _beautySetView.hidden = YES;
    _stickerSetView.hidden = YES;
    _audioMixSetView.hidden = YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
