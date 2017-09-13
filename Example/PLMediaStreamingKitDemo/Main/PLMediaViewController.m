//
//  PLMediaViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/23.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import "PLMediaViewController.h"

#import "PLConfigurationViewController.h"
#import "PLSessionViewController.h"
#import "PLFilterViewController.h"
#import "PLScanViewController.h"

@interface PLMediaViewController ()<
 /* PLMediaStreamingSession 协议*/
 /*             \/             */
 PLMediaStreamingSessionDelegate,

 UITextFieldDelegate,
 PLFilterVcDelegate,
 PLConfigurationVcDelegate,
 PLSessionVcDelegate,
 PLScanViewControlerDelegate
>

# warning PLMediaStreamingSession 是推流中的核心类
@property (nonatomic, strong) PLMediaStreamingSession *streamingSession;

/// 视频采集配置
@property (nonatomic, strong) PLVideoCaptureConfiguration *videoCaptureCon;
/// 视频流配置
@property (nonatomic, strong) PLVideoStreamingConfiguration *videoStreamCon;
/// 音频采集配置
@property (nonatomic, strong) PLAudioCaptureConfiguration *audioCaptureCon;
/// 音频流配置
@property (nonatomic, strong) PLAudioStreamingConfiguration *audioStreamCon;

@property (nonatomic, strong) PLAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSURL *streamURL;

/// 推流URL 输入框
@property (nonatomic, strong) UITextField *urlTextField;
/// 播放二维码生成按钮
@property (nonatomic, strong) UIButton *qrCodeButton;
/// 扫描推流二维码生成推流地址
@property (nonatomic, strong) UIButton *scanButton;

@property (nonatomic, strong) NSMutableDictionary *beautyDict;
@property (nonatomic, assign) BOOL needProcessVideo;

/// 是否是图片推流
@property (nonatomic, assign) BOOL imageStream;

/// 记录是否是纯音频
@property (nonatomic, assign) BOOL onlyAudio;

@property (nonatomic, assign) BOOL isEmpty;


@end

@implementation PLMediaViewController

- (void)dealloc{
    /// 销毁 session
    [self.streamingSession destroy];
    
    /// 清空存储
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"configure"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"session"];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = COLOR_RGB(210, 210, 210, 1);

    
    [self layoutMediaStreamingInterface];
    [self configureMediaStreaming];
}

# pragma mark ---- 推流配置 ----
- (void)configureMediaStreaming{
    _streamURL = [NSURL URLWithString:@"rtmp://pili-publish.liujingbo.echohu.top/liujingbo/fengwenxiu"];

    /// 视频采集
    self.videoCaptureCon = [PLVideoCaptureConfiguration defaultConfiguration];
   
    
    /// 视频编码
    self.videoStreamCon = [PLVideoStreamingConfiguration defaultConfiguration];
    self.videoStreamCon.videoSize = CGSizeMake(400, 720);
    self.videoStreamCon.expectedSourceVideoFrameRate = 24;
    self.videoStreamCon.videoMaxKeyframeInterval = 72;
    self.videoStreamCon.averageVideoBitRate = 768;
    
    
    /// 音频采集
    self.audioCaptureCon = [PLAudioCaptureConfiguration defaultConfiguration];
    
    
    /// 音频编码
    self.audioStreamCon = [PLAudioStreamingConfiguration defaultConfiguration];
    self.audioStreamCon.encodedAudioSampleRate = 48000;
    

    /// PLMediaStreamingSession 初始化
    self.streamingSession = [[PLMediaStreamingSession alloc]initWithVideoCaptureConfiguration:_videoCaptureCon audioCaptureConfiguration:_audioCaptureCon videoStreamingConfiguration:_videoStreamCon audioStreamingConfiguration:_audioStreamCon stream:nil];

    [self configureMediaStreamingSession];
}

# pragma mark ---- session 基本设置 ----
- (void)configureMediaStreamingSession{
    self.streamingSession.previewView.frame = CGRectMake(0, 0, KSCREEN_WIDTH, KSCREEN_HEIGHT);
    self.streamingSession.previewView.backgroundColor = COLOR_RGB(246, 246, 246, 1);
    
    self.imageStream = NO;
    
    /// 话筒采集音量
    self.streamingSession.inputGain = 1;
    
    self.streamingSession.delegate = self;
    [self.streamingSession setBeautifyModeOn:YES];
    self.needProcessVideo = NO;
    /// 美颜三项指标，初设为0.5
    [self.streamingSession setBeautify:0.5];
    [self.streamingSession setWhiten:0.5];
    [self.streamingSession setRedden:0.5];
    _beautyDict = [NSMutableDictionary dictionaryWithDictionary:@{@"beauty":@"0.5", @"whiten":@"0.5", @"readden":@"0.5"}];
    
    /// 添加水印
    [self.streamingSession setWaterMarkWithImage:[UIImage imageNamed:@"qiniu"] position:CGPointMake(50, 500)];
    /// 预览视图 拍摄效果
    [self.view insertSubview:_streamingSession.previewView atIndex:0];
}

# pragma mark ---- PLMediaStreamingSession  delegate ----
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session streamStateDidChange:(PLStreamState)state
{
    NSString *streamStatusStr = [NSString string];
    switch (state) {
        case 0:
            streamStatusStr = @"未知状态";
            break;
        case 1:
            streamStatusStr = @"连接中状态";
            break;
        case 2:
            streamStatusStr = @"已连接状态";
            break;
        case 3:
            streamStatusStr = @"断开连接中状态";
            break;
        case 4:
            streamStatusStr = @"已断开连接状态";
            break;
        case 5:
            streamStatusStr = @"正在等待自动重连状态";
            break;
        case 6:
            streamStatusStr = @"错误状态";
            break;
        default:
            break;
    }
    NSLog(@"流状态 --------- %@", streamStatusStr);
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didDisconnectWithError:(NSError *)error
{
    NSLog(@"流状态 错误 ---- %@", error);
}

- (CVPixelBufferRef)mediaStreamingSession:(PLMediaStreamingSession *)session cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    if (_needProcessVideo) {
        size_t w = CVPixelBufferGetWidth(pixelBuffer);
        size_t h = CVPixelBufferGetHeight(pixelBuffer);
        size_t par = CVPixelBufferGetBytesPerRow(pixelBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        uint8_t *pimg = CVPixelBufferGetBaseAddress(pixelBuffer);
        for (int i = 0; i < w; i ++){
            for (int j = 0; j < h; j++){
                pimg[j * par + i * 4 + 1] = 255;
            }
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return pixelBuffer;
    } else{
        return pixelBuffer;
    }
}

# pragma mark ---- 布局推流界面 ----
- (void)layoutMediaStreamingInterface{
    UIButton *backButton = [[UIButton alloc]init];
    backButton.backgroundColor = BUTTON_BACKGROUNDCOLOR;
    backButton.layer.cornerRadius = 5;
    [backButton addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchDown];
    [backButton setImage:[UIImage imageNamed:@"pl_back"] forState:UIControlStateNormal];
    [self.view addSubview:backButton];
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(38, 28));
        make.leftMargin.mas_equalTo(0);
        make.topMargin.mas_equalTo(29);
    }];
    
    UIView *textFieldView = [[UIView alloc]init];
    textFieldView.backgroundColor = BUTTON_BACKGROUNDCOLOR;
    textFieldView.layer.cornerRadius = 5;
    [self.view addSubview:textFieldView];
    [textFieldView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(KSCREEN_WIDTH - 142, 28));
        make.leftMargin.mas_equalTo(48);
        make.topMargin.mas_equalTo(29);
    }];
    
    _urlTextField = [[UITextField alloc]init];
    _urlTextField.backgroundColor = COLOR_RGB(172, 172, 172, 0.8);
    _urlTextField.backgroundColor = [UIColor clearColor];
    _urlTextField.delegate = self;
    _urlTextField.placeholder = @"输入推流地址";
    _urlTextField.keyboardType = UIKeyboardTypeURL;
    [_urlTextField setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_urlTextField setValue:FONT_MEDIUM(13) forKeyPath:@"_placeholderLabel.font"];
    _urlTextField.font = FONT_MEDIUM(14);
    _urlTextField.textColor = [UIColor whiteColor];
    [textFieldView addSubview:_urlTextField];
    [_urlTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(KSCREEN_WIDTH - 150, 28));
        make.leftMargin.mas_equalTo(8);
        make.topMargin.mas_equalTo(0);
    }];
    
    UIButton *playButton = [[UIButton alloc] init];
    playButton.backgroundColor = BUTTON_BACKGROUNDCOLOR;
    playButton.layer.cornerRadius = 5;
    [playButton addTarget:self action:@selector(streamControl:) forControlEvents:UIControlEventTouchDown];
    [playButton setTitle:@"开始推流" forState:UIControlStateNormal];
    playButton.titleLabel.font = FONT_MEDIUM(14);
    [self.view addSubview:playButton];
    [playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(66, 28));
        make.rightMargin.mas_equalTo(0);
        make.topMargin.mas_equalTo(30);
    }];
    
    
    /// 摄像头转换、开音／静音、视频／音频、美颜／素颜
    NSArray *buttonArray1 = @[@"pl_camera", @"pl_nosound", @"pl_audio", @"pl_nobeauty", @"截图", @"水印"];
    for (NSInteger i = 0; i < 6; i++) {
        UIButton *button = [[UIButton alloc] init];
        button.backgroundColor = BUTTON_BACKGROUNDCOLOR;
        button.tag = 100 + i;
        [button addTarget:self action:@selector(plCommonButtonAction:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:button];
        CGSize buttonSize;
        CGFloat top;
        if (i < 4) {
            top = 80 + i * 52;
            buttonSize = CGSizeMake(38, 38);
            button.layer.cornerRadius = 19;
            [button setImage:[UIImage imageNamed:buttonArray1[i]] forState:UIControlStateNormal];
        } else{
            top = 246 + 42 * (i - 3);
            buttonSize = CGSizeMake(46, 28);
            button.layer.cornerRadius = 3;
            button.titleLabel.font = FONT_MEDIUM(14);
            [button setTitle:buttonArray1[i] forState:UIControlStateNormal];
        }
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
            make.rightMargin.mas_equalTo(0);
            make.topMargin.mas_equalTo(top);
        }];
    }
    
    _qrCodeButton = [[UIButton alloc]init];
    _qrCodeButton.layer.cornerRadius = 5;
    _qrCodeButton.backgroundColor = BUTTON_BACKGROUNDCOLOR;
    [_qrCodeButton addTarget:self action:@selector(createQRcode) forControlEvents:UIControlEventTouchDown];
    [_qrCodeButton setImage:[UIImage imageNamed:@"pl_qrCode"] forState:UIControlStateNormal];
    [self.view addSubview:_qrCodeButton];
    [_qrCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(36, 36));
        make.rightMargin.mas_equalTo(0);
        make.topMargin.mas_equalTo(372);
    }];
    
    _scanButton = [[UIButton alloc]init];
    _scanButton.layer.cornerRadius = 5;
    _scanButton.backgroundColor = BUTTON_BACKGROUNDCOLOR;
    [_scanButton addTarget:self action:@selector(scanCode:) forControlEvents:UIControlEventTouchDown];
    [_scanButton setImage:[UIImage imageNamed:@"pl_scan"] forState:UIControlStateNormal];
    [self.view addSubview:_scanButton];
    [_scanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(36, 36));
        make.rightMargin.mas_equalTo(0);
        make.topMargin.mas_equalTo(420);
    }];
    
    /// PLMediaStreamingSession   configuration／session／filter 、 图片推流 - 开／关
    CGFloat totalWidth = 0;
    NSArray *buttonArray2 = @[@"Configuration", @"Session", @"Filter", @"图片推流 - 开"];
    for (NSInteger i = 0; i < 4; i++) {
        UIButton *button = [[UIButton alloc]init];
        button.layer.cornerRadius = 5;
        button.tag = 100 + i;
        button.backgroundColor = BUTTON_BACKGROUNDCOLOR;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = FONT_MEDIUM(14);
        [button setTitle:buttonArray2[i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(plClassifyButtonAction:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:button];


        CGRect bounds = [buttonArray2[i] boundingRectWithSize:CGSizeMake(1000, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:FONT_MEDIUM(15) forKey:NSFontAttributeName] context:nil];
        CGFloat width = bounds.size.width;
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(width, 28));
            make.leftMargin.mas_equalTo(totalWidth);
            make.bottomMargin.mas_equalTo(-15);
        }];
        totalWidth += width;
        totalWidth += 6;
    }
}

# pragma mark ---- CommonButton ----
- (void)plCommonButtonAction:(UIButton *)button{
    NSInteger index = button.tag - 100;
    button.selected = !button.selected;
    if (index == 0) {
        if (!_imageStream) {
            [self.streamingSession toggleCamera];
        }
    } else if (index == 1) {
        if (!button.selected) {
            [button setImage:[UIImage imageNamed:@"pl_nosound"] forState:UIControlStateNormal];
            self.streamingSession.muted = NO;
        } else {
            [button setImage:[UIImage imageNamed:@"pl_sound"] forState:UIControlStateNormal];
            self.streamingSession.muted = YES;
        }
    } else if (index == 2) {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"音视频推流切换" message:@"亲，切换推流方式，会先断流再重新推流！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
//            [self dismissView];
        }];
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (!button.selected) {
                [button setImage:[UIImage imageNamed:@"pl_audio"] forState:UIControlStateNormal];
                _onlyAudio = NO;
            } else {
                [button setImage:[UIImage imageNamed:@"pl_video"] forState:UIControlStateNormal];
                _onlyAudio = YES;
            }
            [self restartStreamingWithNewConfiguration];
        }];
        [alertVc addAction:cancelAction];
        [alertVc addAction:sureAction];
        [self presentViewController:alertVc animated:YES completion:nil];
    } else if (index == 3) {
        if (!_imageStream) {
            if (!button.selected) {
                [button setImage:[UIImage imageNamed:@"pl_nobeauty"] forState:UIControlStateNormal];
                _beautyDict = [NSMutableDictionary dictionaryWithDictionary:@{@"beauty":@"0.5", @"whiten":@"0.5", @"readden":@"0.5"}];
                [self.streamingSession setBeautifyModeOn:YES];
            } else {
                [button setImage:[UIImage imageNamed:@"pl_beauty"] forState:UIControlStateNormal];
                _beautyDict = [NSMutableDictionary dictionaryWithDictionary:@{@"beauty":@"0.0", @"whiten":@"0.0", @"readden":@"0.0"}];
                [self.streamingSession setBeautifyModeOn:NO];
            }
        } else{
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"目前处于图片推流中，不可以开启或关闭美颜～，请切换至视频推流后，再修改！" preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:alertVc animated:YES completion:^{
                [self performSelector:@selector(dismissView) withObject:nil afterDelay:3];
            }];
        }
        
    } else if (index == 4) {
        [_streamingSession getScreenshotWithCompletionHandler:^(UIImage * _Nullable image) {
            if (image == nil) {
                return;
            }
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }];
    } else if (index == 5) {
        if (!_imageStream) {
            if (!button.selected) {
                [self.streamingSession setWaterMarkWithImage:[UIImage imageNamed:@"qiniu"] position:CGPointMake(80, 500)];
            } else {
                [self.streamingSession clearWaterMark];
            }
        }
    }
}

# pragma mark ---- ClassifyButton ----
- (void)plClassifyButtonAction:(UIButton *)button{
    NSInteger index = button.tag - 100;
    button.selected = !button.selected;
    if (index == 0) {
        PLConfigurationViewController *configurationVc = [[PLConfigurationViewController alloc]init];
        configurationVc.delegate = self;
        configurationVc.imageStream = _imageStream;
        [self presentViewController:configurationVc animated:NO completion:nil];
    } else if (index == 1) {
        PLSessionViewController *sessionVc = [[PLSessionViewController alloc]init];
        sessionVc.delegate = self;
        sessionVc.imageStream = _imageStream;
        [self presentViewController:sessionVc animated:NO completion:nil];
    } else if (index == 2) {
        PLFilterViewController *filterVc = [[PLFilterViewController alloc]init];
        filterVc.delegate = self;
        filterVc.imageStream = _imageStream;
        filterVc.beautyDict = [_beautyDict copy];
        filterVc.needProcessVideo = _needProcessVideo;
        [self presentViewController:filterVc animated:NO completion:nil];
    } else{
        NSString *title = [button titleForState:UIControlStateNormal];
        if ([title isEqualToString:@"图片推流 - 开"]) {
            [self showAlertViewForPictureStreaming];
            [button setTitle:@"图片推流 - 关" forState:UIControlStateNormal];
            [self.streamingSession setPushImage:[UIImage imageNamed:@"pushImage"]];
        } else {
            _imageStream = NO;
            [button setTitle:@"图片推流 - 开" forState:UIControlStateNormal];
            [self.streamingSession setPushImage:nil];
        }
    }
}

# pragma mark ---- 开始／停止 推流 ----
- (void)streamControl:(UIButton *)button{
    [self verifyStreamUrlWithText:_urlTextField.text isStream:button.selected];
    button.selected = !button.selected;
    if (button.selected) {
        [button setTitle:@"停止推流" forState:UIControlStateNormal];
        [self.streamingSession startStreamingWithPushURL:_streamURL feedback:^(PLStreamStartStateFeedback feedback) {
            // feedback 推流操作开始的状态
        }];
    } else {
        [button setTitle:@"开始推流" forState:UIControlStateNormal];
        [self.streamingSession stopStreaming];
    }
}

- (void)showAlertViewForPictureStreaming{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"图片推流" message:@"亲，是否要选择图片推流 ？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
        _imageStream = NO;
        [self dismissView];
    }];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _imageStream = YES;
        [self.streamingSession setPushImage:[UIImage imageNamed:@"pushImage"]];
    }];
    [alertVc addAction:cancelAction];
    [alertVc addAction:sureAction];
    [self presentViewController:alertVc animated:YES completion:nil];
}

# pragma mark ---- UIImageWriteToSavedPhotosAlbum ----
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"亲，截图已成功保存至相册～" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertVc animated:YES completion:^{
        [self performSelector:@selector(dismissView) withObject:nil afterDelay:3];
    }];
}

- (void)dismissView{
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark ---- PLConfigVcDelegate ----
- (void)configureStreamWithConfigureModel:(PLConfigureModel *)configureModel categoryModel:(PLCategoryModel *)categoryModel{
    NSInteger index = [configureModel.selectedNum integerValue];
    /// PLVideoCaptureConfiguration
    if ([categoryModel.categoryKey isEqualToString:@"PLVideoCaptureConfiguration"]) {
        if ([configureModel.configuraKey containsString:@"videoFrameRate"]) {
            _streamingSession.videoFrameRate = [configureModel.configuraValue[index] integerValue];
        } else if ([configureModel.configuraKey containsString:@"sessionPreset"]){
            if ([IOS_SYSTEM_STRING compare:@"9.0.0"] >= 0){
                switch (index) {
                    case 0:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset352x288;
                        break;
                    case 1:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset640x480;
                        break;
                    case 2:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset1280x720;
                        break;
                    case 3:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset1920x1080;
                        break;
                    case 4:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset3840x2160;
                        break;
                    case 5:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetLow;
                        break;
                    case 6:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetMedium;
                        break;
                    case 7:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetHigh;
                        break;
                    case 8:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetPhoto;
                        break;
                    case 9:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetiFrame960x540;
                        break;
                    case 10:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
                        break;
                    case 11:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetInputPriority;
                        break;
                    default:
                        break;
                }
            } else {
                switch (index) {
                    case 0:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset352x288;
                        break;
                    case 1:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset640x480;
                        break;
                    case 2:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset1280x720;
                        break;
                    case 3:
                        _streamingSession.sessionPreset = AVCaptureSessionPreset1920x1080;
                        break;
                    case 4:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetLow;
                        break;
                    case 5:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetMedium;
                        break;
                    case 6:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetHigh;
                        break;
                    case 7:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetPhoto;
                        break;
                    case 8:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetiFrame960x540;
                        break;
                    case 9:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
                        break;
                    case 10:
                        _streamingSession.sessionPreset = AVCaptureSessionPresetInputPriority;
                        break;
                    default:
                        break;
                }
            }
        } else if ([configureModel.configuraKey containsString:@"previewMirrorFrontFacing"]){
            if (index == 0) {
                _streamingSession.previewMirrorFrontFacing = NO;
            } else{
                _streamingSession.previewMirrorFrontFacing = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"previewMirrorRearFacing"]){
            if (index == 0) {
                _streamingSession.previewMirrorRearFacing = NO;
            } else{
                _streamingSession.previewMirrorRearFacing = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"streamMirrorFrontFacing"]){
            if (index == 0) {
                _streamingSession.streamMirrorFrontFacing = NO;
            } else{
                _streamingSession.streamMirrorFrontFacing = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"streamMirrorRearFacing"]){
            if (index == 0) {
                _streamingSession.streamMirrorRearFacing = NO;
            } else{
                _streamingSession.streamMirrorRearFacing = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"cameraPositon"]){
            switch (index) {
                case 0:
                    _streamingSession.captureDevicePosition = AVCaptureDevicePositionUnspecified;
                    break;
                case 1:
                    _streamingSession.captureDevicePosition = AVCaptureDevicePositionBack;
                    break;
                case 2:
                    _streamingSession.captureDevicePosition = AVCaptureDevicePositionFront;
                    break;
                default:
                    break;
            }
        } else if ([configureModel.configuraKey containsString:@"videoOrientation"]){
            _streamingSession.videoOrientation = index + 1;
        }
        
    /// PLVideoStreamingConfiguration
    } else if ([categoryModel.categoryKey isEqualToString:@"PLVideoStreamingConfiguration"]) {
        if ([configureModel.configuraKey containsString:@"videoProfileLevel"]) {
            switch (index) {
                case 0:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264Baseline30;
                    break;
                case 1:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264Baseline31;
                    break;
                case 2:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264Baseline41;
                    break;
                case 3:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264BaselineAutoLevel;
                    break;
                case 4:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264Main30;
                    break;
                case 5:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264Main31;
                    break;
                case 6:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264Main32;
                    break;
                case 7:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264Main41;
                    break;
                case 8:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264MainAutoLevel;
                    break;
                case 9:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264High40;
                    break;
                case 10:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264High41;
                    break;
                case 11:
                    _videoStreamCon.videoProfileLevel = AVVideoProfileLevelH264HighAutoLevel;
                    break;
                default:
                    break;
            }
        } else if ([configureModel.configuraKey containsString:@"videoSize"]){
            switch (index) {
                case 0:
                    _videoStreamCon.videoSize = CGSizeMake(272, 480);
                    break;
                case 1:
                    _videoStreamCon.videoSize = CGSizeMake(368, 640);
                    break;
                case 2:
                    _videoStreamCon.videoSize = CGSizeMake(400, 720);
                    break;
                case 3:
                    _videoStreamCon.videoSize = CGSizeMake(720, 1280);
                    break;
                default:
                    break;
            }
        } else if ([configureModel.configuraKey containsString:@"expectedSourceVideoFrameRate"]){
            _videoStreamCon.expectedSourceVideoFrameRate = [configureModel.configuraValue[index] integerValue];
        } else if ([configureModel.configuraKey containsString:@"videoMaxKeyframeInterval"]){
            _videoStreamCon.videoMaxKeyframeInterval = [configureModel.configuraValue[index] integerValue];
        } else if ([configureModel.configuraKey containsString:@"averageVideoBitRate"]){
            _videoStreamCon.averageVideoBitRate = [configureModel.configuraValue[index] integerValue];
        } else if ([configureModel.configuraKey containsString:@"videoEncoderType"]){
            if (index == 0) {
                _videoStreamCon.videoEncoderType = PLH264EncoderType_AVFoundation;
                
            } else{
                _videoStreamCon.videoEncoderType = PLH264EncoderType_VideoToolbox;
            }
        }
        [_streamingSession reloadVideoStreamingConfiguration:_videoStreamCon];
    
    /// PLAudioCaptureConfiguration
    } else if ([categoryModel.categoryKey isEqualToString:@"PLAudioCaptureConfiguration"]) {
        if ([configureModel.configuraKey containsString:@"channelsPerFrame"]) {
            if (index == 0) {
                _streamingSession.audioCaptureConfiguration.channelsPerFrame = 1;
            } else{
                _streamingSession.audioCaptureConfiguration.channelsPerFrame = 2;
            }
        } else if ([configureModel.configuraKey containsString:@"acousticEchoCancellationEnable"]){
            if (index == 0) {
                _streamingSession.audioCaptureConfiguration.acousticEchoCancellationEnable = NO;
            } else{
                _streamingSession.audioCaptureConfiguration.acousticEchoCancellationEnable = YES;
            }
        }
        
    /// PLAudioStreamingConfiguration
    } else if ([categoryModel.categoryKey isEqualToString:@"PLAudioStreamingConfiguration"]) {
        if ([configureModel.configuraKey containsString:@"encodedAudioSampleRate"]) {
            _streamingSession.audioStreamingConfiguration.encodedAudioSampleRate = index;
        } else if ([configureModel.configuraKey containsString:@"audioBitRate"]){
            switch (index) {
                case 0:
                    _streamingSession.audioStreamingConfiguration.audioBitRate = PLStreamingAudioBitRate_64Kbps;
                    break;
                case 1:
                    _streamingSession.audioStreamingConfiguration.audioBitRate = PLStreamingAudioBitRate_96Kbps;
                    break;
                case 2:
                    _streamingSession.audioStreamingConfiguration.audioBitRate = PLStreamingAudioBitRate_128Kbps;
                    break;
                default:
                    break;
            }
        } else if ([configureModel.configuraKey containsString:@"encodedNumberOfChannels"]){
            if (index == 0) {
                _streamingSession.audioStreamingConfiguration.encodedNumberOfChannels = 1;
            } else{
                _streamingSession.audioStreamingConfiguration.encodedNumberOfChannels = 2;
            }
        } else if ([configureModel.configuraKey containsString:@"audioEncoderType"]){
            switch (index) {
                case 0:
                    _streamingSession.audioStreamingConfiguration.audioEncoderType = PLAACEncoderType_iOS_AAC;
                    break;
                case 1:
                    _streamingSession.audioStreamingConfiguration.audioEncoderType = PLAACEncoderType_fdk_AAC_LC;
                    break;
                case 2:
                    _streamingSession.audioStreamingConfiguration.audioEncoderType = PLAACEncoderType_fdk_AAC__HE_BSR;
                    break;
                default:
                    break;
            }
        }
    }
}

# pragma mark ---- PLSessiomVcDelegate ----
- (void)configureSessionWithConfigureModel:(PLConfigureModel *)configureModel categoryModel:(PLCategoryModel *)categoryModel{
    NSInteger index = [configureModel.selectedNum integerValue];
    
    /// PLStreamingKit
    if ([categoryModel.categoryKey isEqualToString:@"PLStreamingKit"]) {
        if ([configureModel.configuraKey containsString:@"statusUpdateInterval"]) {
            _streamingSession.statusUpdateInterval = [configureModel.configuraValue[index] integerValue];
            
        } else if ([configureModel.configuraKey containsString:@"dynamicFrameEnable"]){
            if (index == 0) {
                _streamingSession.dynamicFrameEnable = NO;
            } else{
                _streamingSession.dynamicFrameEnable = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"autoReconnectEnable"]){
            if (index == 0) {
                _streamingSession.autoReconnectEnable = NO;
            } else{
                _streamingSession.autoReconnectEnable = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"monitorNetworkStateEnable"]){
            if (index == 0) {
                _streamingSession.monitorNetworkStateEnable = NO;
            } else{
                _streamingSession.monitorNetworkStateEnable = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"threshold"]){
            _streamingSession.threshold = [configureModel.configuraValue[index] floatValue];
        } else if ([configureModel.configuraKey containsString:@"maxCount"]){
            _streamingSession.maxCount = [configureModel.configuraValue[index] integerValue];
        }
    
    /// CameraSource
    } else if ([categoryModel.categoryKey isEqualToString:@"CameraSource"]) {
        if ([configureModel.configuraKey containsString:@"continuousAutofocusEnable"]) {
            if (index == 0) {
                _streamingSession.continuousAutofocusEnable = NO;
            } else{
                _streamingSession.continuousAutofocusEnable = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"touchToFocusEnable"]){
            if (index == 0) {
                _streamingSession.touchToFocusEnable = NO;
            } else{
                _streamingSession.touchToFocusEnable = YES;
            }
            
        } else if ([configureModel.configuraKey containsString:@"smoothAutoFocusEnabled"]){
            if (index == 0) {
                _streamingSession.smoothAutoFocusEnabled = YES;
            } else{
                _streamingSession.smoothAutoFocusEnabled = NO;
            }
            
        } else if ([configureModel.configuraKey containsString:@"torchOn"]){
            if (index == 0) {
                _streamingSession.torchOn = NO;
            } else{
                _streamingSession.torchOn = YES;
            }
        }
    
    /// MicrophoneSource
    } else if ([categoryModel.categoryKey isEqualToString:@"MicrophoneSource"]) {
        if ([configureModel.configuraKey containsString:@"playback"]) {
            if (index == 0) {
                _streamingSession.playback = NO;
            } else{
                _streamingSession.playback = YES;
            }
        } else if ([configureModel.configuraKey containsString:@"inputGain"]){
            _streamingSession.inputGain = [configureModel.configuraValue[index] floatValue];
            
        } else if ([configureModel.configuraKey containsString:@"allowAudioMixWithOthers"]){
            if (index == 0) {
                _streamingSession.allowAudioMixWithOthers = NO;
            } else{
                _streamingSession.allowAudioMixWithOthers = YES;
            }
        }
        
    /// Applictaion
    } else if ([categoryModel.categoryKey isEqualToString:@"Applictaion"]) {
        
        if ([configureModel.configuraKey containsString:@"idleTimerDisable"]) {
            if (index == 0) {
                _streamingSession.idleTimerDisable = NO;
            } else{
                _streamingSession.idleTimerDisable = YES;
            }
        }
        
    /// AudioEffect
    } else if ([categoryModel.categoryKey isEqualToString:@"AudioEffect"]) {
        
        if ([configureModel.configuraKey isEqualToString:@"预设的混响音效配置"]) {
            NSArray<PLAudioEffectConfiguration *> *configs;
            switch (index) {
                case 0:
                    configs = @[];
                    break;
                case 1:
                    configs = @[[PLAudioEffectModeConfiguration reverbLowLevelModeConfiguration]];
                    break;
                case 2:
                    configs = @[[PLAudioEffectModeConfiguration reverbMediumLevelModeConfiguration]];
                    break;
                case 3:
                    configs = @[[PLAudioEffectModeConfiguration reverbHeightLevelModeConfiguration]];
                    break;
            }
            _streamingSession.audioEffectConfigurations = configs;
        }
        
    /// PLAudioPlayer
    } else if ([categoryModel.categoryKey isEqualToString:@"PLAudioPlayer"]){
        if ([configureModel.configuraKey containsString:@"open player"]) {
            if (index == 0) {
                [_streamingSession closeCurrentAudio];
                _audioPlayer = nil;
            } else{
                NSString *audioPath =  [[NSBundle mainBundle] pathForResource:@"TestMusic1" ofType:@"mp3"];
                _audioPlayer = [_streamingSession audioPlayerWithFilePath:audioPath];
                [_audioPlayer play];
            }
            
        } else if ([configureModel.configuraKey containsString:@"musicFiles"]){
            NSDictionary *musicDict = @{@"M1":@"TestMusic1.mp3", @"M2":@"TestMusic2.wav", @"M3":@"TestMusic3.wav", @"M4":@"TestMusic4.mp3", @"M5":@"TestMusic5.mp3"};
            NSString *selectedStr = configureModel.configuraValue[index];
            NSString *fileName = musicDict[selectedStr];
            NSArray *arr = [fileName componentsSeparatedByString:@"."];
            NSString *audioPath = [[NSBundle mainBundle] pathForResource:arr[0] ofType:arr[1]];
            if (_audioPlayer) {
                _audioPlayer.audioFilePath = audioPath;
            }
        } else if ([configureModel.configuraKey containsString:@"volume"]){
            if (_audioPlayer) {
                _audioPlayer.volume = [configureModel.configuraValue[index] floatValue];
            } else{
                _audioPlayer.volume = 0;
            }
        } else if ([configureModel.configuraKey containsString:@"audioDidPlayedRate"]){
            if (_audioPlayer) {
                _audioPlayer.audioDidPlayedRate = [configureModel.configuraValue[index] floatValue];
            } else{
                _audioPlayer.audioDidPlayedRate = 0;
            }
        } 
    }
}

# pragma mark ---- PLFilterVcDelegate ----
- (void)filterChangeBeautyDic:(NSDictionary *)dict{
    _beautyDict = [NSMutableDictionary dictionaryWithDictionary:dict];
    CGFloat beauty = [_beautyDict[@"beauty"] floatValue];
    CGFloat whiten = [_beautyDict[@"whiten"] floatValue];
    CGFloat redden = [_beautyDict[@"redden"] floatValue];
    if (beauty == 0 && whiten == 0 && redden == 0) {
        [self.streamingSession setBeautifyModeOn:NO];
    } else {
        [self.streamingSession setBeautifyModeOn:YES];
    }
    [self.streamingSession setBeautify:beauty];
    [self.streamingSession setWhiten:whiten];
    [self.streamingSession setRedden:redden];
}

- (void)filetrNeedPixelBufferOn:(BOOL)needProcessVideo{
    _needProcessVideo = needProcessVideo;
}

# pragma mark ---- 改变设置 ----
- (void)restartStreamingWithNewConfiguration{
    /// 改变设置 并重新推流
    if ([self.streamingSession isStreamingRunning]) {
        [self.streamingSession stopStreaming];
        if (_onlyAudio) {
            self.streamingSession = [[PLMediaStreamingSession alloc]initWithVideoCaptureConfiguration:nil audioCaptureConfiguration:_audioCaptureCon videoStreamingConfiguration:nil audioStreamingConfiguration:_audioStreamCon stream:nil];
        } else {
            self.streamingSession = [[PLMediaStreamingSession alloc]initWithVideoCaptureConfiguration:_videoCaptureCon audioCaptureConfiguration:_audioCaptureCon videoStreamingConfiguration:_videoStreamCon audioStreamingConfiguration:_audioStreamCon stream:nil];
        }
        [self.streamingSession startStreamingWithPushURL:_streamURL feedback:^(PLStreamStartStateFeedback feedback) {
            // feedback 推流操作开始的状态
        }];
        
    /// 仅改变设置
    } else{
        if (_onlyAudio) {
            self.streamingSession = [[PLMediaStreamingSession alloc]initWithVideoCaptureConfiguration:nil audioCaptureConfiguration:_audioCaptureCon videoStreamingConfiguration:nil audioStreamingConfiguration:_audioStreamCon stream:nil];
        } else {
            self.streamingSession = [[PLMediaStreamingSession alloc]initWithVideoCaptureConfiguration:_videoCaptureCon audioCaptureConfiguration:_audioCaptureCon videoStreamingConfiguration:_videoStreamCon audioStreamingConfiguration:_audioStreamCon stream:nil];
        }
    }
}

# pragma mark ---- 生成二维码 供扫描播放 ----
- (void)createQRcode{
    if (!_streamURL) {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"还没有获取到 streamJson 没有可供播放的二维码哦" delegate:nil cancelButtonTitle:@"知道啦" otherButtonTitles:nil] show];
    } else {
//        NSString *url = @"拉流地址";

        NSString *url = @"rtmp://pili-live-rtmp.liujingbo.echohu.top/liujingbo/fengwenxiu";
        UIImage *image = [self createQRForString:url];
        UIControl *screenMaskView = ({
            UIControl *mask = [[UIControl alloc] init];
            [self.view addSubview:mask];
            UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
            [mask addSubview:imgView];
            [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(204, 204));
                make.center.equalTo(mask);
            }];
            [mask mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.left.right.and.bottom.equalTo(self.view);
            }];
            mask;
        });
        [screenMaskView addTarget:self action:@selector(tapQRCodeImageView:)
                 forControlEvents:UIControlEventTouchUpInside];
    }
}

# pragma mark ---- 移除二维码 ----
- (void)tapQRCodeImageView:(UIView *)screenMask
{
    [screenMask removeFromSuperview];
}

# pragma mark ---- 生成二维码 ----
- (UIImage *)createQRForString:(NSString *)qrString
{
    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    return [[UIImage alloc] initWithCIImage:qrFilter.outputImage];
}

# pragma mark ---- 扫描二维码 获取推流地址 ----
- (void)scanCode:(id)sender {
    PLScanViewController *scanVc = [PLScanViewController new];
    scanVc.delegate = self;
    [self presentViewController:scanVc animated:YES completion:nil];
}

# pragma mark ---- PLScanViewControllerDelegate ----
- (void)scanQRResult:(NSString *)qrString {
    NSURL *url = [NSURL URLWithString:qrString];
    if (url) {
        _urlTextField.text = qrString;
        _streamURL = url;
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"scan url error" message:qrString delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [alertView show];
    }
}

# pragma mark ---- urlTextField 回收键盘 ----
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

# pragma mark ---- urlTextField delegate ----
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self verifyStreamUrlWithText:textField.text isStream:self.streamingSession.isStreamingRunning];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    self.streamURL = [NSURL URLWithString:textField.text];
    return YES;
}

# pragma mark ---- 检验推流地址格式 ----
- (void)verifyStreamUrlWithText:(NSString *)text isStream:(BOOL)isStream{
    NSString *messageStr;
    if (text != nil) {
        if ([text containsString:@"rtmp://"] && ![text isEqualToString:@"rtmp://"]) {
            self.streamURL = [NSURL URLWithString:text];
            messageStr = @"推流地址格式正确，可以开始推流了 ！";
            [_urlTextField resignFirstResponder];
        } else{
            messageStr = @"推流地址格式错误，请重新填写 ！";
        }
//    } else {
//        messageStr = @"推流地址未填写，使用默认地址推流 ！";
////        self.streamURL = [NSURL URLWithString:@"推流地址"];
//        self.streamURL = [NSURL URLWithString:@"rtmp://pili-publish.liujingbo.echohu.top/liujingbo/fengwenxiu"];
    }
    if (!isStream) {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:messageStr preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertVc animated:YES completion:^{
            [self performSelector:@selector(dismissView) withObject:nil afterDelay:2];
        }];
    }
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
