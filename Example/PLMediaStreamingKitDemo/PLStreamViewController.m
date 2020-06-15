//
//  PLStreamViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2020/6/8.
//  Copyright © 2020 Pili. All rights reserved.
//

#import "PLStreamViewController.h"
#import "PLButtonControlsView.h"
#import "PLShowDetailView.h"
#import "PLAssetReader.h"

// 系统录屏 ReplayKit
#import <ReplayKit/ReplayKit.h>

// 流状态 String
static NSString *StreamState[] = {
    @"PLStreamStateUnknow",
    @"PLStreamStateConnecting",
    @"PLStreamStateConnected",
    @"PLStreamStateDisconnecting",
    @"PLStreamStateDisconnected",
    @"PLStreamStateAutoReconnecting",
    @"PLStreamStateError"
};

// bundleId 授权状态 String
static NSString *AuthorizationStatus[] = {
    @"PLAuthorizationStatusNotDetermined",
    @"PLAuthorizationStatusRestricted",
    @"PLAuthorizationStatusDenied",
    @"PLAuthorizationStatusAuthorized"
};

// 音频混音文件错误 String
static NSString *AudioFileError[] = {
    @"PLAudioPlayerFileError_FileNotExist",
    @"PLAudioPlayerFileError_FileOpenFail",
    @"PLAudioPlayerFileError_FileReadingFail"
};

@interface PLStreamViewController ()
<
// PLMediaStreamingSession 的代理
PLMediaStreamingSessionDelegate,
// PLAudioPlayer 的代理
PLAudioPlayerDelegate,
// PLStreamingSession 的代理
PLStreamingSessionDelegate,

// 系统 RPBroadcast
RPBroadcastActivityViewControllerDelegate,
RPBroadcastControllerDelegate,

// 自定义 view 的代理
PLButtonControlsViewDelegate,
PLShowDetailViewDelegate
>
{
    // 用于外部导入时，音视频解码时间戳同步
    CFAbsoluteTime startActualFrameTime;
}

// 视频采集配置
@property (nonatomic, strong) PLVideoCaptureConfiguration *videoCaptureConfiguration;
// 视频流配置
@property (nonatomic, strong) PLVideoStreamingConfiguration *videoStreamConfiguration;
// 音频采集配置
@property (nonatomic, strong) PLAudioCaptureConfiguration *audioCaptureConfiguration;
// 音频流配置
@property (nonatomic, strong) PLAudioStreamingConfiguration *audioStreamingConfiguration;

// 推流混音播放器
@property (nonatomic, strong) PLAudioPlayer *audioPlayer;

// UI
@property (nonatomic, strong) PLButtonControlsView *buttonControlsView;
@property (nonatomic, strong) UILabel *streamLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) PLShowDetailView *detailView;
@property (nonatomic, strong) UIImageView *pushImageView;
@property (nonatomic, strong) UISlider *zoomSlider;

@property (nonatomic, assign) CGFloat topSpace;

// 外部导入数据
@property (nonatomic, strong) PLAssetReader *assetReader;
@property (nonatomic, assign, getter=isRunning) BOOL running;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, assign) CGFloat frameRate;

// 计时
@property (nonatomic, strong) UILabel *timingLabel;
@property (nonatomic, strong) NSTimer *timer;

// 录屏
@property (nonatomic, strong) RPBroadcastActivityViewController *broadcastAVC;
@property (nonatomic, strong) RPBroadcastController *broadcastController;
@property (nonatomic, assign) BOOL isReplayRunning;
@end

@implementation PLStreamViewController

- (void)dealloc {
    // 必须移除监听
    [self removeObservers];
    
    // 销毁计时器，防止内存泄漏
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    // 停止录屏
    if (_isReplayRunning) {
        [self stopReplayLive];
    }
    
    // 销毁 PLMediaStreamingSession
    if (_mediaSession.isStreamingRunning) {
        [_mediaSession stopStreaming];
    }
    _mediaSession.delegate = nil;
    _mediaSession = nil;
    
    // 销毁 PLStreamingSession
    if (_streamSession.isRunning) {
        [_streamSession stop];
    }
    _streamSession.delegate = nil;
    _streamSession = nil;
    
    // 打印代表 PLStreamViewController 成功释放
    NSLog(@"[PLStreamViewController] dealloc !");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    // UI 适配顶部
    CGFloat space = 24;
    if (PL_iPhoneX || PL_iPhoneXR || PL_iPhoneXSMAX) {
        space = 44;
    }
    _topSpace = space + 4;
        
    // 音视频采集推流
    if (_mediaSession && _type == 0) {
        [self configurateAVMediaStreamingSession];
        [self layoutButtonViewInterface];
        
    // 纯音频采集推流
    } else if (_mediaSession && _type == 1) {
        // 遵守代理 PLMediaStreamingSessionDelegate
        _mediaSession.delegate = self;

        // 纯音频 本地背景板
        UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 24, KSCREEN_WIDTH, KSCREEN_HEIGHT - 24)];
        backImageView.image = [UIImage imageNamed:@"pl_audio_only_bg"];
        [self.view addSubview:backImageView];
    // 外部数据导入推流
    } else if (_streamSession && _type == 2) {
        // 遵守代理 PLStreamingSessionDelegate
        _streamSession.delegate = self;
        
        // AVAsset 解码，获取音视频数据
        [self initAssetReader];
        
        // 提示 label
        UILabel *tintLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, KSCREEN_WIDTH, 26)];
        tintLabel.center = self.view.center;
        tintLabel.font = FONT_MEDIUM(11);
        tintLabel.textColor = [UIColor blackColor];
        tintLabel.textAlignment = NSTextAlignmentCenter;
        tintLabel.text = @"将直接使用选择的视频进行推流，请至拉流端观看！";
        [self.view addSubview:tintLabel];
    // 录屏推流
    } else if (_streamSession && _type == 3) {
        // 遵守代理 PLStreamingSessionDelegate
        _streamSession.delegate = self;
                
        // 计时时间显示
        _timingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, KSCREEN_WIDTH, 26)];
        _timingLabel.center = self.view.center;
        _timingLabel.font = FONT_MEDIUM(12);
        _timingLabel.textColor = [UIColor blackColor];
        _timingLabel.textAlignment = NSTextAlignmentCenter;
        _timingLabel.text = [NSString stringWithFormat:@"当前时间: %@", [self getCurrentTime]];
        [self.view addSubview:_timingLabel];
        // 计时器
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timingAction:) userInfo:nil repeats:YES];
    }
    
    // 布局 button 控件视图
    [self layoutCommonView];
    
    // 添加退前后台监听处理
    [self addObservers];
}

#pragma mark - 音视频采集推流
- (void)configurateAVMediaStreamingSession {
    // 配置采集预览视图
    _mediaSession.previewView.frame = CGRectMake(0, 0, KSCREEN_WIDTH, KSCREEN_HEIGHT);
    _mediaSession.previewView.backgroundColor = COLOR_RGB(246, 246, 246, 1);
    
    // 遵守代理 PLMediaStreamingSessionDelegate
    _mediaSession.delegate = self;
    
    // 添加预览视图到父视图
    [self.view insertSubview:_mediaSession.previewView atIndex:0];
    
    // 美颜配置开启，且参数均为 0.5
    [_mediaSession setBeautifyModeOn:YES];
    [_mediaSession setBeautify:0.5];
    [_mediaSession setWhiten:0.5];
    [_mediaSession setRedden:0.5];
    
    // 混音配置
    _audioPlayer = [_mediaSession audioPlayerWithFilePath:[[NSBundle mainBundle] pathForResource:@"TestMusic1" ofType:@"m4a"]];
    _audioPlayer.delegate = self;
    _audioPlayer.volume = 0.5;
}

#pragma mark - PLMediaStreamingSessionDelegate
// 推流时流状态变更的回调
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        _streamLabel.text = StreamState[state];
        NSLog(@"[PLStreamViewController] 流状态: %@", StreamState[state]);
    });
}

// 推流失去连接发生错误的回调
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didDisconnectWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[PLStreamViewController] 失去连接发生错误: error %@, code %ld", error.localizedDescription, error.code);
    });
}

// 推流中流数据信息的更新回调
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session streamStatusDidUpdate:(PLStreamStatus *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        _statusLabel.text = [NSString stringWithFormat:@"video %.1f fps\naudio %.1f fps\ntotal bitrate %.1f kbps",status.videoFPS, status.audioFPS, status.totalBitrate/1000];
        NSLog(@"[PLStreamViewController] PLStreamStatus 的信息: video FPS %.1f, audio FPS %.1f, total bitrate %.1f", status.videoFPS, status.audioFPS, status.totalBitrate);
    });
}

// 提前获取摄像头和麦克风的使用授权，避免出现 session 部分配置未生效的问题
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didGetCameraAuthorizationStatus:(PLAuthorizationStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[PLStreamViewController] 摄像头授权状态: %@", AuthorizationStatus[status]);
    });
}
// 提前获取摄像头和麦克风的使用授权，避免出现 session 部分配置未生效的问题
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didGetMicrophoneAuthorizationStatus:(PLAuthorizationStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[PLStreamViewController] 麦克风授权状态: %@", AuthorizationStatus[status]);
    });
}

// 摄像头采集的数据回调
- (CVPixelBufferRef)mediaStreamingSession:(PLMediaStreamingSession *)session cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    /* 滤镜处理示例，仅供参考
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
     */
    return pixelBuffer;
}

// 麦克风采集的数据回调
- (AudioBuffer *)mediaStreamingSession:(PLMediaStreamingSession *)session microphoneSourceDidGetAudioBuffer:(AudioBuffer *)audioBuffer {
    return audioBuffer;
}

#pragma mark - PLAudioPlayerDelegate
// 音频播放发生错误的回调
- (void)audioPlayer:(PLAudioPlayer *)audioPlayer findFileError:(PLAudioPlayerFileError)fileError {
    dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[PLStreamViewController] 音频文件发生错误: %@", AudioFileError[fileError]);
    });
}

// 音频播放进度的变化回调
- (void)audioPlayer:(PLAudioPlayer *)audioPlayer audioDidPlayedRateChanged:(double)audioDidPlayedRate {
    dispatch_async(dispatch_get_main_queue(), ^{
        _detailView.progressSlider.value = (float)audioDidPlayedRate;
    });
}

// 音频播放是否循环的回调
- (BOOL)didAudioFilePlayingFinishedAndShouldAudioPlayerPlayAgain:(PLAudioPlayer *)audioPlayer {
    // 以下 3 种场景可根据需求选择实现
    
    // 1）播放结束就停止
//    return NO;
    
    // 2）播放结束后，继续从头播放音频
    return YES;
    
    // 3）播放结束后，替换音频文件从头开始播放
//    NSString *audioPath = [[NSBundle mainBundle] pathForResource:@"TestMusic2" ofType:@"wav"];
//    audioPlayer.audioFilePath = audioPath;
//    return YES;
}

- (void)layoutCommonView {
    // 返回按钮
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(10, _topSpace, 65, 26)];
    backButton.backgroundColor = COLOR_RGB(0, 0, 0, 0.3);
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    backButton.titleLabel.font = FONT_MEDIUM(12.f);
    [backButton addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:backButton];

    // 流状态 label
    _streamLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _topSpace + 32, 150, 26)];
    _streamLabel.font = FONT_MEDIUM(11);
    _streamLabel.textColor = COLOR_RGB(181, 68, 68, 1);
    _streamLabel.textAlignment = NSTextAlignmentLeft;
    _streamLabel.text = @"";
    [self.view addSubview:_streamLabel];

    // 流信息 label
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _topSpace + 58, 150, 60)];
    _statusLabel.backgroundColor = COLOR_RGB(0, 0, 0, 0.3);
    _statusLabel.font = FONT_LIGHT(11);
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.textAlignment = NSTextAlignmentLeft;
    _statusLabel.numberOfLines = 0;
    _statusLabel.text = @"video 0.0 fps\naudio 0.0 fps\ntotal bitrate 0.0kbps";
    [self.view addSubview:_statusLabel];
    
    // SEI 按钮
    UIButton *seiButton = [[UIButton alloc] initWithFrame:CGRectMake(10, _topSpace + 130, 65, 26)];
    seiButton.backgroundColor = COLOR_RGB(0, 0, 0, 0.3);
    [seiButton setTitle:@"发送 SEI" forState:UIControlStateNormal];
    [seiButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    seiButton.titleLabel.font = FONT_MEDIUM(12.f);
    [seiButton addTarget:self action:@selector(pushSEIData:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:seiButton];
    
    // 开始/停止推流按钮
    UIButton *startButton = [[UIButton alloc] initWithFrame:CGRectMake(10, _topSpace + 168, 65, 26)];
    startButton.backgroundColor = COLOR_RGB(0, 0, 0, 0.3);
    [startButton setTitle:@"开始推流" forState:UIControlStateNormal];
    [startButton setTitle:@"停止推流" forState:UIControlStateSelected];
    [startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    startButton.titleLabel.font = FONT_MEDIUM(12.f);
    [startButton addTarget:self action:@selector(startStream:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:startButton];
}

#pragma mark - UI 视图
- (void)layoutButtonViewInterface {
    // 摄像头转换按钮
    UIButton *cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(KSCREEN_WIDTH/2 - 15, _topSpace, 30, 30)];
    [cameraButton setImage:[UIImage imageNamed:@"pl_switch_camera"] forState:UIControlStateNormal];
    cameraButton.titleLabel.font = FONT_MEDIUM(12.f);
    [cameraButton addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:cameraButton];
    
    // 按钮控件视图
    _buttonControlsView = [[PLButtonControlsView alloc] initWithFrame:CGRectMake(KSCREEN_WIDTH - 75, _topSpace, 65, 496) show:YES];
    _buttonControlsView.delegate = self;
    [self.view addSubview:_buttonControlsView];
    
    // 细节设置 view
    _detailView = [[PLShowDetailView alloc] initWithFrame:CGRectMake(0, KSCREEN_HEIGHT, KSCREEN_WIDTH, 0)];
    _detailView.delegate = self;
    [self.view addSubview:_detailView];
    
    // 图片推流 覆盖卡住的预览视图
    _pushImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    // 缩放的滑条
    _zoomSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, KSCREEN_HEIGHT - 50, KSCREEN_WIDTH - 30, 30)];
    _zoomSlider.value = 1.0;
    _zoomSlider.minimumValue = 1.0;
    // 获取相机实际的 videoMaxZoomFactor
    _zoomSlider.maximumValue = MIN(5, _mediaSession.videoActiveFormat.videoMaxZoomFactor);
    [_zoomSlider addTarget:self action:@selector(zoomVideo:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_zoomSlider];
}

#pragma mark - PLButtonControlsViewDelegate
- (void)buttonControlsView:(PLButtonControlsView *)buttonControlsView didClickIndex:(NSInteger)index selected:(BOOL)selected {
    if (index == 1) {
        // 预览镜像
        if (_mediaSession.captureDevicePosition == AVCaptureDevicePositionBack) {
            _mediaSession.previewMirrorRearFacing = selected;
        }
        if (_mediaSession.captureDevicePosition == AVCaptureDevicePositionFront) {
            _mediaSession.previewMirrorFrontFacing = selected;
        }
        
    } else if (index == 2) {
        // 编码镜像
        if (_mediaSession.captureDevicePosition == AVCaptureDevicePositionBack) {
            _mediaSession.streamMirrorRearFacing = selected;
        }
        if (_mediaSession.captureDevicePosition == AVCaptureDevicePositionFront) {
            _mediaSession.streamMirrorFrontFacing = selected;
        }

    } else if (index == 3) {
        // 打开/关闭 扬声器
        _mediaSession.muteSpeaker = selected;
    } else if (index == 4) {
        // 打开/关闭 麦克风
        _mediaSession.muteMicrophone = selected;
    } else if (index == 11) {
        // 截图
        [_mediaSession getScreenshotWithCompletionHandler:^(UIImage * _Nullable image) {
            if (image == nil) {
                return;
            }
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }];
    } else if (index == 12) {
        // 人工报障
        [_mediaSession postDiagnosisWithCompletionHandler:^(NSString * _Nullable diagnosisResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewAlert:[NSString stringWithFormat:@"人工报障结果：%@！", diagnosisResult]];
                NSLog(@"[PLStreamViewController] diagnosisResult:%@", diagnosisResult);
            });
        }];
    } else {
        // 其他见 自定义视频 PLShowDetailViewDelegate 的回调处理
        NSInteger currentIndex;
        if (index == 0) {
            currentIndex = 0;
        } else{
            currentIndex = index - 4;
        }
        if (selected) {
            _zoomSlider.hidden = YES;
            [_detailView showDetailSettingViewWithType:currentIndex];
        } else{
            _zoomSlider.hidden = NO;
            [_detailView hideDetailSettingView];
        }
    }
}

#pragma mark - PLShowDetailViewDelegate
- (void)showDetailView:(PLShowDetailView *)showDetailView didClickIndex:(NSInteger)index currentType:(PLSetDetailViewType)type {
    // 转换方向
    if (type == PLSetDetailViewOrientaion) {
        // 摄像头采集方向数组
        NSArray *videoOrientationArray = @[@(AVCaptureVideoOrientationPortrait), @(AVCaptureVideoOrientationPortraitUpsideDown), @(AVCaptureVideoOrientationLandscapeRight), @(AVCaptureVideoOrientationLandscapeLeft)];
        _mediaSession.videoOrientation = [videoOrientationArray[index] integerValue];
    }
    // 图片推流
    if (type == PLSetDetailViewImagePush) {
        NSArray *imageArray = @[@"", @"pushImage_720x1280", @"pushImage_leave"];
        NSString *imageStr = imageArray[index];
        
        if (imageStr.length != 0) {
            UIImage *image = [UIImage imageNamed:imageStr];
            [_mediaSession setPushImage:image];
            
            _pushImageView.image = image;
            [self.view insertSubview:_pushImageView aboveSubview:_mediaSession.previewView];
        } else {
            [_mediaSession setPushImage:nil];
            [_pushImageView removeFromSuperview];
        }
    }
    // 水印
    if (type == PLSetDetailViewWaterMark) {
        NSArray *imageArray = @[@"", @"qiniu", @"xiaoqi1", @"xiaoqi2"];
        NSString *imageStr = imageArray[index];
        if (imageStr.length != 0) {
            [_mediaSession setWaterMarkWithImage:[UIImage imageNamed:imageStr] position:CGPointMake(KSCREEN_WIDTH - 300, KSCREEN_HEIGHT - 100)];
        } else {
            [_mediaSession clearWaterMark];
        }
    }
    // 音效
    if (type == PLSetDetailViewAudioEffect) {
        switch (index) {
            case 0:
                _mediaSession.audioEffectConfigurations = nil;;
                break;
            case 1:
                _mediaSession.audioEffectConfigurations = @[[PLAudioEffectModeConfiguration reverbLowLevelModeConfiguration]];;
                break;
            case 2:
                _mediaSession.audioEffectConfigurations = @[[PLAudioEffectModeConfiguration reverbMediumLevelModeConfiguration]];;
                break;
            case 3:
                _mediaSession.audioEffectConfigurations = @[[PLAudioEffectModeConfiguration reverbHeightLevelModeConfiguration]];;
                break;

            default:
                break;
        }
    }
}

// 美颜调节
- (void)showDetailView:(PLShowDetailView *)showDetailView didChangeBeautyMode:(BOOL)beautyMode beauty:(CGFloat)beauty white:(CGFloat)white red:(CGFloat)red {
    [_mediaSession setBeautifyModeOn:beautyMode];
    [_mediaSession setBeautify:beauty];
    [_mediaSession setWhiten:white];
    [_mediaSession setRedden:red];
}

// 添加贴纸
- (void)showDetailView:(PLShowDetailView *)showDetailView didAddStickerView:(PLPasterView *)stickerView {
    _mediaSession.overlaySuperView.frame = _mediaSession.previewView.bounds;
    [_mediaSession.previewView addSubview:_mediaSession.overlaySuperView];
    [_mediaSession addOverlayView:stickerView];
}
// 移除贴纸
- (void)showDetailView:(PLShowDetailView *)showDetailView didRemoveStickerView:(PLPasterView *)stickerView {
    [_mediaSession removeOverlayView:stickerView];
}
// 刷新贴纸
- (void)showDetailView:(PLShowDetailView *)showDetailView didRefreshStickerView:(PLPasterView *)stickerView {
    [_mediaSession refreshOverlayView:stickerView];
}

// 混音播放状态 注意：开始推流了，才回正常播放
- (void)showDetailView:(PLShowDetailView *)showDetailView didUpdateAudioPlayer:(BOOL)play playBack:(BOOL)playBack file:(nonnull NSString *)file {
    if (![_audioPlayer.audioFilePath isEqualToString:file]) {
        if (_audioPlayer.isRunning) {
            [_audioPlayer pause];
        }
        _audioPlayer.audioFilePath = file;
    }
    _mediaSession.playback = playBack;
    if (play) {
        [_audioPlayer play];
    } else{
        [_audioPlayer pause];
    }
}
// 混音播放音量
- (void)showDetailView:(PLShowDetailView *)showDetailView didUpdateAudioPlayVolume:(CGFloat)volume {
    _audioPlayer.volume = volume;
}
// 混音播放进度
- (void)showDetailView:(PLShowDetailView *)showDetailView didUpdateAudioPlayProgress:(CGFloat)progress {
    _audioPlayer.audioDidPlayedRate = progress;
}

#pragma mark - buttons event
// 切换摄像头
- (void)switchCamera {
    [_mediaSession toggleCamera];
    _zoomSlider.value = 1.0;
    _zoomSlider.minimumValue = 1.0;
    _zoomSlider.maximumValue = MIN(5, _mediaSession.videoActiveFormat.videoMaxZoomFactor);
}

// 开始/停止推流
- (void)startStream:(UIButton *)button {
    button.selected = !button.selected;
    // PLMediaStreamingSession
    if (_type == 0 || _type == 1) {
        // 开始/停止 推流
        if (button.selected) {
            [_mediaSession startStreamingWithPushURL:_pushURL feedback:^(PLStreamStartStateFeedback feedback) {
                [self streamStateAlert:feedback];
            }];
        } else{
            [_mediaSession stopStreaming];
        }
    }
    // PLStreamingSession
    if (_type == 2 || _type == 3) {
        // 开始/停止 推流
        if (button.selected) {
            // 开始外部数据导入
            if (_assetReader) {
                [self startPushBuffer];
            // 启动录屏
            } else{
                if (@available(iOS 11.0, *)) {
                    // 注意选择 broadcast 将以 broadcast view 中的 URL 进行推流
                    [self loadBroadcast];
                }
            }
            [_streamSession startWithPushURL:_pushURL feedback:^(PLStreamStartStateFeedback feedback) {
                [self streamStateAlert:feedback];
            }];
        } else{
            [_streamSession stop];
            // 停止外部数据导入
            if (_assetReader) {
                [self stopPushBuffer];
            //
            } else{
                if (@available(iOS 11.0, *)) {
                    [self stopReplayLive];
                }
            }
        }
    }
}

// 发送 SEI
- (void)pushSEIData:(UIButton *)button {
    if (_mediaSession && _mediaSession.isStreamingRunning) {
        [_mediaSession pushSEIMessage:@"media session push sei data" repeat:1];
        [self presentViewAlert:@"插入 SEI 成功，该功能需搭配支持 SEI 的播放器方可验证！"];
    } else{
        if (_mediaSession) {
            [self presentViewAlert:@"请先开始推流！"];
        }
    }
    if (_streamSession && _streamSession.isRunning) {
        [_streamSession pushSEIMessage:@"stream session push sei data" repeat:1];
        [self presentViewAlert:@"插入 SEI 成功，该功能需搭配支持 SEI 的播放器方可验证！"];
    } else{
        if (_streamSession) {
            [self presentViewAlert:@"请先开始推流！"];
        }
    }
}

// 预览视图缩放
- (void)zoomVideo:(UISlider *)slider {
    _mediaSession.videoZoomFactor = slider.value;
}

#pragma mark - PLStreamingSessionDelegate
// 流状态发生变化的回调
- (void)streamingSession:(PLStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        _streamLabel.text = StreamState[state];
        NSLog(@"[PLStreamViewController] 流状态: %@", StreamState[state]);
    });
}

// 失去连接发生错误的回调
- (void)streamingSession:(PLStreamingSession *)session didDisconnectWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[PLStreamViewController] 失去连接发生错误: error %@, code %ld", error.localizedDescription, error.code);
    });
}

// 流信息更新的回调
- (void)streamingSession:(PLStreamingSession *)session streamStatusDidUpdate:(PLStreamStatus *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        _statusLabel.text = [NSString stringWithFormat:@"video %.1f fps\naudio %.1f fps\ntotal bitrate %.1f kbps",status.videoFPS, status.audioFPS, status.totalBitrate/1000];
        NSLog(@"[PLStreamViewController] PLStreamStatus 的信息: video FPS %.1f, audio FPS %.1f, total bitrate %.1f", status.videoFPS, status.audioFPS, status.totalBitrate);
    });
}

#pragma mark - 外部数据导入的相关操作
- (void)initAssetReader {
    _frameRate = 15;
    _lock = [[NSLock alloc] init];
    _assetReader = [[PLAssetReader alloc] initWithURL:self.mediaURL frameRate:_frameRate stereo:NO];
    int width = 0;
    int heigit = 0;
    float frameRate = 0;
    CMTime duration = kCMTimeZero;
    [_assetReader getVideoInfo:&width height:&heigit frameRate:&frameRate duration:&duration];
    _frameRate = frameRate;
}
// 音视频推流速率和音视频同步策略:
// 开始推流的时候，获取一个当前绝对时间、作为开始推流时间点。在获取推流数据 CMSampleBuffer 之后，再获取一个当前绝对时间，
// 与推流开始的时候时间点做时间差，得到一个时长，这个时长就是音视频数据应该推的时长，
// 视频数据
- (void)videoPushProc {
    @autoreleasepool {
        while (self.isRunning) {
            [self.lock lock];
            CMSampleBufferRef sample = [self.assetReader readVideoSampleBuffer];
            if (!sample) {
                // 没有获取到 sample 被认为是推流文件到尾端，开启一个新的推流循环
                [self.assetReader seekTo:kCMTimeZero frameRate:15];
            }
            [self.lock unlock];
            
            if (sample) {
                [_streamSession pushVideoSampleBuffer:sample];
                
                // Do this outside of the video processing queue to not slow that down while waiting
                CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sample);
                CFAbsoluteTime currentActualTime = CFAbsoluteTimeGetCurrent();
                CFAbsoluteTime duration = CMTimeGetSeconds(currentSampleTime);
                if (duration > currentActualTime - startActualFrameTime) {
                    [NSThread sleepForTimeInterval:duration - (currentActualTime - startActualFrameTime)];
                }
                CFRelease(sample);
            }
        }
    }
}
// 音频数据
- (void)audioPushProc {
    @autoreleasepool {
        while (self.isRunning) {
            [self.lock lock];
            CMSampleBufferRef sample = [self.assetReader readAudioSampleBuffer];
            if (!sample) {
                [self.assetReader seekTo:kCMTimeZero frameRate:15];
                [self resetTime];
            }
            [self.lock unlock];
            if (sample) {
                [_streamSession pushAudioSampleBuffer:sample];
                
                CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sample);
                CFAbsoluteTime currentActualTime = CFAbsoluteTimeGetCurrent();
                CFAbsoluteTime duration = CMTimeGetSeconds(currentSampleTime);
                if (duration > currentActualTime - startActualFrameTime) {
                    [NSThread sleepForTimeInterval:duration - (currentActualTime - startActualFrameTime)];
                }
                CFRelease(sample);
            }
        }
    }
}
// 开始推 buffer
- (void)startPushBuffer {
    [self.lock lock];
    if (self.isRunning) {
        [self.lock unlock];
        return;
    }
    self.running = YES;
    [self.assetReader seekTo:kCMTimeZero frameRate:_frameRate];
    [self resetTime];
    if (_assetReader.hasVideo) {
        [NSThread detachNewThreadSelector:@selector(videoPushProc) toTarget:self withObject:nil];
    } else {
        NSLog(@"[PLStreamViewController] media with no video data!");
    }
    if (_assetReader.hasAudio) {
        [NSThread detachNewThreadSelector:@selector(audioPushProc) toTarget:self withObject:nil];
    } else {
        NSLog(@"[PLStreamViewController] media with no audio data!");
    }
    [self.lock unlock];
}
// 停止推 buffer
- (void)stopPushBuffer {
    self.running = NO;
}
// 重置时间戳
-(void)resetTime {
    startActualFrameTime = CFAbsoluteTimeGetCurrent();
}

#pragma mark - 录屏相关
- (void)loadBroadcast {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.qbox"];
    [userDefaults setObject:@(PLStreamStateUnknow) forKey:@"PLReplayStreamState"];
    if (!_isReplayRunning) {
        [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    self.broadcastAVC = broadcastActivityViewController;
                    self.broadcastAVC.delegate = self;
                    [self presentViewController:self.broadcastAVC animated:YES completion:nil];
                } else {
                   NSLog(@"[PLStreamViewController] loadBroadcast, error code %ld description %@", error.code, error.localizedDescription);
                   [self presentViewAlert:[NSString stringWithFormat:@"loadBroadcast 无法启动 ReplayKit 录屏，发生错误 code:%ld %@", error.code, error.localizedDescription]];
                }
            });
        }];
    } else {
        [self stopReplayLive];
    }
}

- (void)stopReplayLive {
    [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"[PLStreamViewController] stopReplayLive finsh broadcast success!");
        } else {
            NSLog(@"[PLStreamViewController] stopReplayLive, error code %ld description %@", error.code, error.localizedDescription);
        }
    }];
    
    [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"[PLStreamViewController] RPScreenRecorder stop recording success!");
        } else {
            NSLog(@"[PLStreamViewController] RPScreenRecorder stop recording, error code %ld description %@", error.code, error.localizedDescription);
        }
    }];
    _isReplayRunning = NO;
}

// RPBroadcastActivityViewControllerDelegate
- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(RPBroadcastController *)broadcastController error:(NSError *)error {
    NSLog(@"[PLStreamViewController] broadcastActivityViewController finsh with broadcast, error code %ld description %@", error.code, error.localizedDescription);
    if (error) {
        [self presentViewAlert:[NSString stringWithFormat:@"结束 broadcast 发生错误 code:%ld %@", error.code, error.localizedDescription]];
        return;
    }
    
    [self.broadcastAVC dismissViewControllerAnimated:YES completion:nil];
    self.broadcastController = broadcastController;
    self.broadcastController.delegate = self;
    
    [RPScreenRecorder sharedRecorder].microphoneEnabled = YES;
    
    [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                if (@available(iOS 11.0, *)) {
                    [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
                        if (bufferType == RPSampleBufferTypeVideo) {
                            [_streamSession pushVideoSampleBuffer:sampleBuffer];
                        }

                        if (bufferType == RPSampleBufferTypeAudioApp) {
                            [_streamSession pushAudioSampleBuffer:sampleBuffer];
                        }

                        if (bufferType == RPSampleBufferTypeAudioMic) {
                            [_streamSession pushAudioSampleBuffer:sampleBuffer];
                        }
                    } completionHandler:^(NSError * _Nullable error) {
                        NSLog(@"[PLStreamViewController] RPScreenRecorder start, error code %ld description %@", error.code, error.localizedDescription);
                    }];
                } else{
                    [self presentViewAlert:@"低于 iOS 11.0 版本，暂不支持！"];
                }
            } else {
                NSLog(@"[PLStreamViewController] start broadcast, error code %ld description %@", error.code, error.localizedDescription);
                [self presentViewAlert:[NSString stringWithFormat:@"无法启动 ReplayKit 录屏，发生错误 code:%ld %@", error.code, error.localizedDescription]];
            }
        });
    }];
}

// RPBroadcastControllerDelegate
- (void)broadcastController:(RPBroadcastController *)broadcastController didFinishWithError:(NSError *)error {
    NSLog(@"[PLStreamViewController] broadcastController 结束时发生错误 error code %ld description %@", error.code, error.localizedDescription);
    if (error) {
        [self presentViewAlert:[NSString stringWithFormat:@"录屏发生错误 code:%ld %@", error.code, error.localizedDescription]];
    }
}
- (void)broadcastController:(RPBroadcastController *)broadcastController didUpdateBroadcastURL:(NSURL *)broadcastURL {
    NSLog(@"[PLStreamViewController] broadcastController 更新 broadcastURL:%@", broadcastURL);
}
- (void)broadcastController:(RPBroadcastController *)broadcastController didUpdateServiceInfo:(NSDictionary<NSString *,NSObject<NSCoding> *> *)serviceInfo {
    NSLog(@"[PLStreamViewController] broadcastController 更新 serviceInfo:%@", serviceInfo);
}

// 计时器事件
- (void)timingAction:(NSTimer *)timer {
    _timingLabel.text = [NSString stringWithFormat:@"当前时间: %@", [self getCurrentTime]];
}

#pragma mark - 退前后台相关处理
- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}
- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}
// 进入后台
- (void)enterBackgroundNotification:(NSNotification *)info {
    if (_type == 2) {
        // AssetReader 使用了硬解
        // 需要在进入后台的时候，停止推流
        [self stopPushBuffer];
    }
}
// 即将进入后台
- (void)willEnterForegroundNotification:(NSNotification *)info {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_type == 2 && _streamSession.isRunning) {
            [self startPushBuffer];
        }
    });
}

#pragma mark - alert view
- (void)presentViewAlert:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:alertAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

// 流状态的统一提示
- (void)streamStateAlert:(PLStreamStartStateFeedback)feedback {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (feedback) {
            case PLStreamStartStateSuccess:
                [self presentViewAlert:@"成功开始推流!"];
                break;
            case PLStreamStartStateSessionUnknownError:
                [self presentViewAlert:@"发生未知错误无法启动!"];
                break;
            case PLStreamStartStateSessionStillRunning:
                [self presentViewAlert:@"已经在运行中，无需重复启动!"];
                break;
            case PLStreamStartStateStreamURLUnauthorized:
                [self presentViewAlert:@"当前的 StreamURL 没有被授权!"];
                break;
            case PLStreamStartStateSessionConnectStreamError:
                [self presentViewAlert:@"建立 socket 连接错误!"];
                break;
            case PLStreamStartStateSessionPushURLInvalid:
                [self presentViewAlert:@"当前传入的 pushURL 无效!"];
                break;
            default:
                break;
        }
    });
}

#pragma mark - 获取当前时间
- (NSString *)getCurrentTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss:SSS"];
    NSDate *datenow = [NSDate date];
    NSString *nowtimeStr = [formatter stringFromDate:datenow];
    return nowtimeStr;
}

#pragma mark - save image to phtoto album delegate
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"亲，截图已成功保存至相册～" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertVc animated:YES completion:^{
        [self performSelector:@selector(dismissView) withObject:nil afterDelay:3];
    }];
}

#pragma mark - 返回上一界面
- (void)dismissView {
    [self dismissViewControllerAnimated:YES completion:nil];
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
