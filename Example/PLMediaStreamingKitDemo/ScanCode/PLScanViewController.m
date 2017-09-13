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

@property (nonatomic, strong) NSString *scanResult;

@end

@implementation PLScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startReading];
    UIButton *closeButton = [[UIButton alloc]init];
    closeButton.layer.cornerRadius = 19;
    [closeButton addTarget:self action:@selector(closeButtonSelected) forControlEvents:UIControlEventTouchDown];
    [closeButton setImage:[UIImage imageNamed:@"pl_close"] forState:UIControlStateNormal];
    [self.view addSubview:closeButton];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(38, 38));
        make.leftMargin.mas_equalTo(4);
        make.topMargin.mas_equalTo(30);
    }];
}

- (void)closeButtonSelected{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopReading];
}

- (BOOL)startReading {
    NSError *error;
    
    /// 初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    /// 用captureDevice创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    /// 创建媒体数据输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    /// 实例化捕捉会话
    _captureSession = [[AVCaptureSession alloc] init];
    
    /// 将添加输入流和媒体输出流到会话
    [_captureSession addInput:input];
    [_captureSession addOutput:captureMetadataOutput];
    
    /// 创建串行队列，并加媒体输出流添加到队列当中
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    /// 设置输出媒体数据类型为QRCode
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    /// 实例化预览图层
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    /// 设置预览图层填充方式
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer:_videoPreviewLayer];
    
    /// 设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(0.2f, 0.2f, 0.8f, 0.8f);
    
    /// 扫描框
    CGSize size = self.view.bounds.size;
    _boxView = [[UIView alloc] initWithFrame:CGRectMake(size.width * 0.2f, (size.height - (size.width - size.width * 0.4f))/2, size.width - size.width * 0.4f, size.width - size.width * 0.4f)];
    _boxView.layer.borderColor = [UIColor greenColor].CGColor;
    _boxView.layer.borderWidth = 1.0f;
    
    [self.view addSubview:_boxView];
    
    /// 扫描线
    _scanLayer = [[CALayer alloc] init];
    _scanLayer.frame = CGRectMake(0, 0, _boxView.bounds.size.width, 1);
    _scanLayer.backgroundColor = [UIColor brownColor].CGColor;
    
    [_boxView.layer addSublayer:_scanLayer];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(moveScanLayer:) userInfo:nil repeats:YES];
    [timer fire];
    
    /// 开始扫描
    [_captureSession startRunning];
    return YES;
}

- (void)stopReading {
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_videoPreviewLayer removeFromSuperlayer];
}

# pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    //判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSLog(@"input QR: %@", [metadataObj stringValue]);
            self.scanResult = [metadataObj stringValue];
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:self.scanResult preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self startReading];
            }];
            UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if ([self.delegate respondsToSelector:@selector(scanQRResult:)]) {
                    [self.delegate scanQRResult:self.scanResult];
                }
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [alertVc addAction:cancelAction];
            [alertVc addAction:sureAction];
            [self presentViewController:alertVc animated:YES completion:nil];
        }
    }
}

- (void)moveScanLayer:(NSTimer *)timer {
    CGRect frame = _scanLayer.frame;
    if (_boxView.frame.size.height < _scanLayer.frame.origin.y) {
        frame.origin.y = 0;
        _scanLayer.frame = frame;
    }else{
        
        frame.origin.y += 5;
        
        [UIView animateWithDuration:0.1 animations:^{
            _scanLayer.frame = frame;
        }];
    }
}

- (BOOL)shouldAutorotate {
    return NO;
}

@end
