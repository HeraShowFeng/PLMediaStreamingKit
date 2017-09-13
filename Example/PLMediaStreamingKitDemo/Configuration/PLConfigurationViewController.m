//
//  PLConfigureViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/26.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import "PLConfigurationViewController.h"

#import "PLSegmentTableViewCell.h"
#import "PLListArrTableViewCell.h"

@interface PLConfigurationViewController ()<
 UITableViewDelegate,
 UITableViewDataSource,
 PLListArrayViewDelegate
>
@property (nonatomic, strong) UITableView *configurTableView;
@property (nonatomic, strong) NSArray *configurArray;

@end

@implementation PLConfigurationViewController
static NSString *segmentIdentifier = @"segmentCell";
static NSString *listIdentifier = @"listCell";
static NSString *saveConfigure = @"configure";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self layoutConfigurationsView];
    [self showMediaStreamingConfigurations];
    
}

- (void)viewDidAppear:(BOOL)animated{
    if (_imageStream) {
        /// 图片推流状态 不可操作视频
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"目前处于图片推流中，不可以修改以下分区视频相关属性: PLVideoCaptureConfiguration 、PLVideoStreamingConfiguration，请切换至视频推流后，再修改！" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertVc animated:YES completion:^{
            [self performSelector:@selector(dismissView) withObject:nil afterDelay:3];
        }];
    }
}

# pragma mark ---- 标题 ----
- (void)layoutConfigurationsView{
    UILabel *titleLab = [[UILabel alloc]init];
    titleLab.font = FONT_MEDIUM(16);
    titleLab.text = @"configurations 设置";
    [self.view addSubview:titleLab];
    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(160, 30));
        make.leftMargin.mas_equalTo(KSCREEN_WIDTH/2 - 80);
        make.topMargin.mas_equalTo(34);
    }];
    
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
    
    self.configurTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 70, KSCREEN_WIDTH, KSCREEN_HEIGHT - 70) style:UITableViewStylePlain];
    self.configurTableView.backgroundColor = [UIColor whiteColor];
    self.configurTableView.delegate = self;
    self.configurTableView.dataSource = self;
    self.configurTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.configurTableView registerClass:[PLSegmentTableViewCell class] forCellReuseIdentifier:segmentIdentifier];
    [self.configurTableView registerClass:[PLListArrTableViewCell class] forCellReuseIdentifier:listIdentifier];
    [self.view addSubview:_configurTableView];
}

# pragma mark ---- PLMediaStreamingKit configure 设置 ----
- (void)showMediaStreamingConfigurations{
    NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
    NSArray *dataArr = [userdafault objectForKey:@"configure"];
    
    
    NSInteger compareOrigin = 0;
    NSString *originVersion = [userdafault objectForKey:@"system_version"];
    if (originVersion) {
         compareOrigin =  [IOS_SYSTEM_STRING compare:originVersion options:NSCaseInsensitiveSearch range:NSMakeRange(0, 1)];
    }
    
    if (dataArr.count != 0 || compareOrigin > 0) {
        NSMutableArray *arr = [NSMutableArray array];
        for (NSData *data in dataArr) {
            PLCategoryModel *categoryModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [arr addObject:categoryModel];
        }
        _configurArray = [arr copy];
    } else {
        NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
        [userdafault setObject:IOS_SYSTEM_STRING forKey:@"system_version"];
        
        /// PLVideoCaptureConfiguration 相关属性
        NSDictionary *videoFrameRateDict = @{@"videoFrameRate - 帧率 ( Default：24fps )":@[@"5", @"15", @"24", @"20", @"30"], @"default":@2};
        
        NSDictionary *sessionPresetDict;
        if ([IOS_SYSTEM_STRING compare:@"9.0.0"] >= 0){
            sessionPresetDict = @{@"sessionPreset - 预览分辨率 ( Default：640x480 )":@[@"352x288", @"640x480", @"1280x720", @"1920x1080", @"3840x2160", @"Low", @"Medium", @"High", @"Photo", @"iFrame960x540", @"iFrame1280x720", @"InputPriority"], @"default":@1};
        } else {
            sessionPresetDict = @{@"sessionPreset - 预览分辨率 ( Default：640x480 )":@[@"352x288", @"640x480", @"1280x720", @"1920x1080", @"Low", @"Medium", @"High", @"Photo", @"iFrame960x540", @"iFrame1280x720", @"InputPriority"], @"default":@1};
        }
       
        NSDictionary *previewMirrorFrontFacingDict = @{@"previewMirrorFrontFacing - 前置预览镜像 ( Default：YES )":@[@"NO", @"YES"], @"default":@1};
        NSDictionary *previewMirrorRearFacingDict = @{@"previewMirrorRearFacing - 后置预览镜像 ( Default：NO )":@[@"NO", @"YES"], @"default":@0};
        NSDictionary *streamMirrorFrontFacingDict = @{@"streamMirrorFrontFacing - 前置推流镜像 ( Default：NO )":@[@"NO", @"YES"], @"default":@0};
        NSDictionary *streamMirrorRearFacingDict = @{@"streamMirrorRearFacing - 后置推流镜像 ( Default：NO )":@[@"NO", @"YES"], @"default":@0};
        NSDictionary *cameraPositionDict = @{@"cameraPositon - 采集摄像头位置 ( Default：Back )":@[@"Unspecified", @"Back", @"Front"], @"default":@1};
        NSDictionary *videoOrientationDict = @{@"videoOrientation - 采集摄像头旋转方向 ( Default：Portrait )":@[@"Portrait", @"PortraitUpsideDown", @"LandscapeRight", @"LandscapeLeft"], @"default":@0};
        
        NSDictionary *videoCaptureDict = @{@"PLVideoCaptureConfiguration":@[videoFrameRateDict, sessionPresetDict, previewMirrorFrontFacingDict, previewMirrorRearFacingDict, streamMirrorFrontFacingDict, streamMirrorRearFacingDict, cameraPositionDict, videoOrientationDict]};
        
        /// PLVideoStreamingConfiguration 相关属性
        NSDictionary *videoProfileLevelDict = @{@"videoProfileLevel - 编码的 Profile Level ( Default：H264Baseline31 )":@[@"H264Baseline30", @"H264Baseline31", @"H264Baseline41", @"H264BaselineAutoLevel", @"H264Main30", @"H264Main31", @"H264Main32", @"H264Main41", @"H264MainAutoLevel", @"H264High40", @"H264High41", @"H264HighAutoLevel"], @"default":@1};
        NSDictionary *videoSizeDict = @{@"videoSize - 编码时的视频分辨率 ( Default：720x1280 )":@[@"272x480", @"368x640", @"400x720", @"720x1280"], @"default":@3};
        NSDictionary *expectedSourceVideoFrameRateDict = @{@"expectedSourceVideoFrameRate - 预期视频的帧率 ( Default：24fps )":@[@"5", @"10", @"15", @"20", @"24", @"30"], @"default":@4};
        NSDictionary *videoMaxKeyframeIntervalDict = @{@"videoMaxKeyframeInterval - 视频编码关键帧最大间隔 ( Default：72fps )":@[@"15", @"30", @"45", @"60", @"72", @"90"], @"default":@4};
        NSDictionary *averageVideoBitRateDict = @{@"averageVideoBitRate - 平均视频编码码率 ( Default：768Kbps )":@[@"256Kbps", @"512Kbps", @"768Kbps", @"1024Kbps", @"1280Kbps", @"1536Kbps", @"2048Kbps"], @"default":@2};
        NSDictionary *videoEncoderTypeDict = @{@"videoEncoderType - H.264 编码器类型 ( Default：AVFoundation )":@[@"AVFoundation", @"VideoToolbox"], @"default":@0};
        
        NSDictionary *videoStreamingDict = @{@"PLVideoStreamingConfiguration":@[videoProfileLevelDict, videoSizeDict, expectedSourceVideoFrameRateDict, videoMaxKeyframeIntervalDict, averageVideoBitRateDict, videoEncoderTypeDict]};
        
        /// PLAudioCaptureConfiguration 相关属性
        NSDictionary *audioCaptureDict = @{@"PLAudioCaptureConfiguration":@[@{@"channelsPerFrame - 采集音频声道数 ( Default：1 )":@[@"1", @"2"], @"default":@0}, @{@"acousticEchoCancellationEnable - 回声消除 ( Default：NO )":@[@"NO", @"YES"], @"default":@0}]};
        
        /// PLAudioStreamingConfiguration 相关属性
        NSDictionary *audioStreamingDict = @{@"PLAudioStreamingConfiguration":@[@{@"encodedAudioSampleRate - 音频采样率 ( Default：48000Hz )":@[@"48000Hz",@"44100Hz",@"22050Hz", @"11025Hz"], @"default":@0}, @{@"audioBitRate - 音频编码比特率 ( Default：96Kbps )":@[@"64Kbps", @"96Kbps", @"128Kbps"], @"default":@1}, @{@"encodedNumberOfChannels - 编码声道数 ( Default：1 )":@[@"1", @"2"], @"default":@0}, @{@"audioEncoderType - 编码模式 ( Default：iOS_AAC )":@[@"iOS_AAC", @"fdk_AAC_LC", @"fdk_AAC__HE_BSR"], @"default":@0}]};
        
        NSArray *configureArr = @[videoCaptureDict, videoStreamingDict, audioCaptureDict, audioStreamingDict];
        
        /// 装入属性数组
        _configurArray = [PLCategoryModel categoryArrayWithArray:configureArr];
    }
}

# pragma mark ---- tableview delegate ----
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _configurArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    PLCategoryModel *categoryModel = _configurArray[section];
    NSArray *array = categoryModel.categoryValue;
    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *titleArray = @[@"PLVideoCaptureConfiguration", @"PLVideoStreamingConfiguration"];

    PLCategoryModel *categoryModel = _configurArray[indexPath.section];
    NSArray *array = categoryModel.categoryValue;
    PLConfigureModel *configureModel = array[indexPath.row];
    NSArray *rowArray = configureModel.configuraValue;
    if ((rowArray.count <= 7 && [rowArray[0] length] < 6) || (rowArray.count <= 3 && [rowArray[1] length] < 10)) {
        PLSegmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentIdentifier forIndexPath:indexPath];
        [cell confugureSegmentCellWithConfigureModel:configureModel];
        cell.segmentControl.tag = 100 * indexPath.section + indexPath.row;
        [cell.segmentControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if ([titleArray containsObject:categoryModel.categoryKey]) {
            if (_imageStream) {
                cell.userInteractionEnabled = NO;
            } else{
                cell.userInteractionEnabled = YES;
            }
        }
        return cell;
    } else{
        PLListArrTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:listIdentifier forIndexPath:indexPath];
        [cell confugureListArrayCellWithConfigureModel:configureModel];
        cell.listButton.tag = 100 * indexPath.section + indexPath.row;
        [cell.listButton addTarget:self action:@selector(listButtonAction:) forControlEvents:UIControlEventTouchDown];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if ([titleArray containsObject:categoryModel.categoryKey]) {
            if (_imageStream) {
                cell.userInteractionEnabled = NO;
            } else{
                cell.userInteractionEnabled = YES;
            }
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    PLCategoryModel *categoryModel = _configurArray[indexPath.section];
    NSArray *array = categoryModel.categoryValue;
    PLConfigureModel *configureModel = array[indexPath.row];
    NSArray *rowArray = configureModel.configuraValue;
    if ((rowArray.count <= 7 && [rowArray[0] length] < 6) || (rowArray.count <= 3 && [rowArray[1] length] < 14)) {
        return [PLSegmentTableViewCell configureSegmentCellHeightWithString:configureModel.configuraKey];
    } else{
        return [PLListArrTableViewCell configureListArrayCellHeightWithString:configureModel.configuraKey];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, KSCREEN_WIDTH, 40)];
    headerView.backgroundColor = [UIColor whiteColor];
    PLCategoryModel *categoryModel = _configurArray[section];
    UILabel *headLab = [[UILabel alloc]initWithFrame:CGRectMake(20, 5, KSCREEN_WIDTH - 40, 30)];
    headLab.font = FONT_MEDIUM(15);
    headLab.textAlignment = NSTextAlignmentLeft;
    headLab.text = [NSString stringWithFormat:@">>> %@", categoryModel.categoryKey];
    [headerView addSubview:headLab];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40.0f;
}

# pragma mark ---- segment action ----
- (void)segmentAction:(UISegmentedControl *)segment{
    NSInteger section = segment.tag / 100;
    NSInteger row = segment.tag % 100;
    PLCategoryModel *categoryModel = _configurArray[section];
    NSArray *array = categoryModel.categoryValue;
    PLConfigureModel *configureModel = array[row];
    
    [self controlPropertiesWithIndex:segment.selectedSegmentIndex configureModel:configureModel categoryModel:categoryModel];
}

# pragma mark ---- listButton action ----
- (void)listButtonAction:(UIButton *)listButton{
    NSInteger section = listButton.tag / 100;
    NSInteger row = listButton.tag % 100;
    PLCategoryModel *categoryModel = _configurArray[section];
    NSArray *array = categoryModel.categoryValue;
    PLConfigureModel *configureModel = array[row];
    NSArray *rowArray = configureModel.configuraValue;

    PLListArrayView *listView = [[PLListArrayView alloc]initWithFrame:CGRectMake(0, 0, KSCREEN_WIDTH, KSCREEN_HEIGHT) listArray:rowArray superView:self.view];
    listView.delegate = self;
    listView.configureModel = configureModel;
    listView.categoryModel = categoryModel;
    NSInteger index = [configureModel.selectedNum integerValue];
    listView.listStr = rowArray[index];
}

# pragma mark ---- PLListArrayViewDelegate ----
- (void)listArrayViewSelectedWithIndex:(NSInteger)index configureModel:(PLConfigureModel *)configureModel categoryModel:(PLCategoryModel *)categoryModel{
    [self controlPropertiesWithIndex:index configureModel:configureModel categoryModel:categoryModel];
}

# pragma mark ---- 是否图片推流 是否禁止操作视频相关属性 ----
- (void)controlPropertiesWithIndex:(NSInteger)index configureModel:(PLConfigureModel *)configureModel categoryModel:(PLCategoryModel *)categoryModel{
    configureModel.selectedNum = [NSNumber numberWithInteger:index];
    [_configurTableView reloadData];
    [self saveConfigurations];
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(configureStreamWithConfigureModel:categoryModel:)]) {
        [self.delegate configureStreamWithConfigureModel:configureModel categoryModel:categoryModel];
        [self closeButtonSelected];
    }
}

- (void)dismissView{
    [self dismissViewControllerAnimated:YES completion:nil];
}


# pragma mark ---- 存储 ----
- (void)saveConfigurations{
    NSMutableArray *dataArr = [NSMutableArray array];
    for (PLCategoryModel * categoryModel in _configurArray) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:categoryModel];
        [dataArr addObject:data];
    }
    NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
    [userdafault setObject:[NSArray arrayWithArray:dataArr] forKey:@"configure"];
    [userdafault synchronize];
}

- (void)closeButtonSelected{
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
