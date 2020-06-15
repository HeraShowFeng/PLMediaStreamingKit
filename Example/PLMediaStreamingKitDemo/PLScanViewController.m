//
//  PLScanViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/7/26.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "PLScanViewController.h"

@interface PLScanViewController ()<
 AVCaptureMetadataOutputObjectsDelegate
>

@property (nonatomic, strong) UIView *boxView;
@property (nonatomic, strong) CALayer *scanLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

// 扫码结果
@property (nonatomic, strong) NSString *scanResult;

@end

@implementation PLScanViewController

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 停止读取
    [self stopReading];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 开始读取
    [self startReading];
    
    [self layoutUIInterface];
}

#pragma mark - 开始扫描
- (BOOL)startReading {
    NSError *error;
    
    // 初始化捕捉设备（AVCaptureDevice），类型为 AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 用 captureDevice 创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    // 创建媒体数据输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    // 实例化捕捉会话
    _captureSession = [[AVCaptureSession alloc] init];
    
    // 将添加输入流和媒体输出流到会话
    [_captureSession addInput:input];
    [_captureSession addOutput:captureMetadataOutput];
    
    // 创建串行队列，并加媒体输出流添加到队列当中
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    // 设置输出媒体数据类型为QRCode
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    // 实例化预览图层
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    // 设置预览图层填充方式
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer:_videoPreviewLayer];
    
    // 设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(0.2f, 0.2f, 0.8f, 0.8f);
    
    // 扫描框
    CGSize size = self.view.bounds.size;
    _boxView = [[UIView alloc] initWithFrame:CGRectMake(size.width * 0.1f, (size.height - (size.width - size.width * 0.2f))/2, size.width - size.width * 0.2f, size.width - size.width * 0.2f)];
    _boxView.layer.borderColor = [UIColor greenColor].CGColor;
    _boxView.layer.borderWidth = 1.0f;
    
    [self.view addSubview:_boxView];
    
    // 扫描线
    _scanLayer = [[CALayer alloc] init];
    _scanLayer.frame = CGRectMake(0, 0, _boxView.bounds.size.width, 1);
    _scanLayer.backgroundColor = COLOR_RGB(16, 169, 235, 1).CGColor;
    
    [_boxView.layer addSublayer:_scanLayer];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(moveScanLayer:) userInfo:nil repeats:YES];
    [timer fire];
    
    // 开始扫描
    [_captureSession startRunning];
    return YES;
}

#pragma mark - 停止扫描
- (void)stopReading {
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_videoPreviewLayer removeFromSuperlayer];
}

#pragma mark - UI 布局
- (void)layoutUIInterface {
    UILabel *titleLab = [[UILabel alloc]initWithFrame:CGRectMake(KSCREEN_WIDTH/2 - 80, 64, 160, 26)];
    titleLab.font = FONT_MEDIUM(13);
    titleLab.text = @"推流地址二维码扫描";
    titleLab.textColor = [UIColor whiteColor];
    titleLab.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLab];
    
    UIButton *closeButton = [[UIButton alloc]initWithFrame:CGRectMake(15, 34, 56, 26)];
    closeButton.backgroundColor = COLOR_RGB(0, 0, 0, 0.3);
    [closeButton addTarget:self action:@selector(closeButtonSelected) forControlEvents:UIControlEventTouchDown];
    [closeButton setTitle:@"返回" forState:UIControlStateNormal];
    closeButton.titleLabel.font = FONT_MEDIUM(12.f);
    [self.view addSubview:closeButton];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 判断是否有数据
        if (metadataObjects != nil && [metadataObjects count] > 0) {
            AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
            // 判断回传的数据类型
            if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
                NSLog(@"input QR: %@", [metadataObj stringValue]);
                self.scanResult = [metadataObj stringValue];
                [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
                UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:self.scanResult preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self startReading];
                    });
                }];
                UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([self.delegate respondsToSelector:@selector(scanQRResult:)]) {
                            [self.delegate scanQRResult:self.scanResult];
                        }
                        [self dismissViewControllerAnimated:YES completion:nil];
                    });
                }];
                [alertVc addAction:cancelAction];
                [alertVc addAction:sureAction];
                [self presentViewController:alertVc animated:YES completion:nil];

            }
        }
    });
}

// 移除扫描框
- (void)moveScanLayer:(NSTimer *)timer {
    CGRect layerFrame = _scanLayer.frame;
    if (_boxView.frame.size.height < _scanLayer.frame.origin.y) {
        layerFrame.origin.y = 0;
        _scanLayer.frame = layerFrame;
    }else{
        layerFrame.origin.y += 5;
        [UIView animateWithDuration:0.1 animations:^{
            _scanLayer.frame = layerFrame;
        }];
    }
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - 返回上个界面
- (void)closeButtonSelected {
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
