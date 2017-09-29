//
//  PLSessionViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by 冯文秀 on 2017/6/26.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import "PLSessionViewController.h"

#import "PLSegmentTableViewCell.h"
#import "PLListArrTableViewCell.h"


@interface PLSessionViewController ()<
 UITableViewDelegate,
 UITableViewDataSource,
 PLListArrayViewDelegate
>

@property (nonatomic, strong) UITableView *sessionTableView;
@property (nonatomic, strong) NSArray *sessionArray;

@end

@implementation PLSessionViewController
static NSString *segmentIdentifier = @"segmentCell";
static NSString *listIdentifier = @"listCell";


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self layoutSessionsView];
    [self showMediaStreamingSessions];
}

- (void)viewDidAppear:(BOOL)animated {
    if (_imageStream) {
        /// 图片推流状态 不可操作视频
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"目前处于图片推流中，不可以修改以下分区视频相关属性：PLStreamingKit 、CameraSource，请切换至视频推流后，再修改！" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertVc animated:YES completion:^{
            [self performSelector:@selector(dismissView) withObject:nil afterDelay:3];
        }];
    }
}

# pragma mark ---- 标题 ----
- (void)layoutSessionsView {
    UILabel *titleLab = [[UILabel alloc]init];
    titleLab.font = FONT_MEDIUM(16);
    titleLab.text = @"session 设置";
    [self.view addSubview:titleLab];
    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(140, 30));
        make.leftMargin.mas_equalTo(KSCREEN_WIDTH/2 - 70);
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
    
    self.sessionTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 70, KSCREEN_WIDTH, KSCREEN_HEIGHT - 70) style:UITableViewStylePlain];
    self.sessionTableView.backgroundColor = [UIColor whiteColor];
    self.sessionTableView.delegate = self;
    self.sessionTableView.dataSource = self;
    self.sessionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.sessionTableView registerClass:[PLSegmentTableViewCell class] forCellReuseIdentifier:segmentIdentifier];
    [self.sessionTableView registerClass:[PLListArrTableViewCell class] forCellReuseIdentifier:listIdentifier];
    [self.view addSubview:_sessionTableView];
}

# pragma mark ---- PLMediaStreamingKit session 设置 ----
- (void)showMediaStreamingSessions {
    NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
    NSArray *dataArr = [userdafault objectForKey:@"session"];
    if (dataArr.count != 0) {
        NSMutableArray *arr = [NSMutableArray array];
        for (NSData *data in dataArr) {
            PLCategoryModel *categoryModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [arr addObject:categoryModel];
        }
        _sessionArray = [arr copy];
    } else {
        /// PLStreamingKit 相关属性
        NSDictionary *statusUpdateIntervalDict = @{@"statusUpdateInterval - 流状态更新间隔 ( Default：3s )":@[@"1", @"3", @"5", @"10", @"15", @"20", @"30"], @"default":@1};
        NSDictionary *dynamicFrameEnableDict = @{@"dynamicFrameEnable - 动态帧率 ( Default：NO )":@[@"NO", @"YES"], @"default":@0};
        NSDictionary *autoReconnectEnableDict = @{@"autoReconnectEnable - 自动断线重连 ( Default：NO )":@[@"NO", @"YES"], @"default":@0};
        NSDictionary *monitorNetworkStateEnableDict = @{@"monitorNetworkStateEnable - 网络切换监测  ( Default：NO )":@[@"NO", @"YES"], @"default":@0};
        NSDictionary *thresholdDict = @{@"threshold - 丢包策略的阀值 ( Default：0.5 )":@[@"0", @"0.5", @"0.25", @"0.75", @"1"], @"default":@0};
        NSDictionary *maxCountDict = @{@"maxCount - 队列最大容纳包 ( Default：300 )":@[@"0", @"50", @"100", @"150", @"300", @"450", @"600"], @"default":@4};
        
        
        NSDictionary *PLStreamingKitDict = @{@"PLStreamingKit":@[statusUpdateIntervalDict, dynamicFrameEnableDict, autoReconnectEnableDict, monitorNetworkStateEnableDict, thresholdDict, maxCountDict]};
        
        /// CameraSource 相关属性
        NSDictionary *cameraSourceDict = @{@"CameraSource": @[@{@"continuousAutofocusEnable - 连续自动对焦 ( Default：YES )":@[@"NO", @"YES"], @"default":@1}, @{@"touchToFocusEnable - 手动对焦 ( Default：YES )":@[@"NO", @"YES"], @"default":@1}, @{@"smoothAutoFocusEnabled - 减缓自动对焦抖动 ( Default：YES )":@[@"NO", @"YES"], @"default":@1}, @{@"torchOn - 手电筒 ( Default：NO )":@[@"NO", @"YES"], @"default":@0}]};
        
        /// MicrophoneSource 相关属性
        NSDictionary *microphoneSourceDict = @{@"MicrophoneSource":@[@{@"playback - 返听功能 ( Default：NO )":@[@"NO", @"YES"], @"default":@0}, @{@"inputGain - 麦克风采集的音量 ( Default：1 )":@[@"1", @"0.75", @"0.5", @"0.25"], @"default":@0}, @{@"allowAudioMixWithOthers - 允许在后台与其他App混音不被打断 ( Default：NO )":@[@"NO", @"YES"], @"default":@0}]};
        
        /// Applictaion
        NSDictionary *applicationDict = @{@"Applictaion":@[@{@"idleTimerDisable - 是否关闭系统屏幕自动锁屏 ( Default：YES )":@[@"NO", @"YES"], @"default":@1}]};
        
        /// AudioEffect 相关属性
        NSDictionary *audioEffectDict = @{@"AudioEffect":@[@{@"预设的混响音效配置 ( Default：None )":@[@"None", @"Low", @"Medium", @"Height"], @"default":@0}]};
        
        /// PLAudioPlayer 相关属性
        NSDictionary *openPlayerDict = @{@"open player - 是否打开PLAudioPlayer ( Default：NO )":@[@"NO", @"YES"], @"default":@0};
        NSDictionary *musicFileDict = @{@"musicFiles - 可选择的音乐文件":@[@"M1", @"M2", @"M3", @"M4"], @"default":@0};
        NSDictionary *volumeDict = @{@"volume - 音量":@[@"0", @"0.25", @"0.5", @"0.75", @"1"], @"default":@2};
        NSDictionary *audioDidPlayedRateDict = @{@"audioDidPlayedRate - 播放进度":@[@"0", @"0.25", @"0.5", @"0.75", @"1"], @"default":@0};
        
        NSDictionary *PLAudioPlayerDict = @{@"PLAudioPlayer":@[openPlayerDict, musicFileDict, volumeDict, audioDidPlayedRateDict]};
        
        
        NSArray *sessionArr = @[PLStreamingKitDict, cameraSourceDict, microphoneSourceDict, applicationDict, audioEffectDict, PLAudioPlayerDict];
        
        /// 装入属性数组
        _sessionArray = [PLCategoryModel categoryArrayWithArray:sessionArr];
    }
}

# pragma mark ---- tableview delegate ----
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sessionArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PLCategoryModel *categoryModel = _sessionArray[section];
    NSArray *array = categoryModel.categoryValue;
    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *titleArray = @[@"PLStreamingKit", @"CameraSource"];
    
    PLCategoryModel *categoryModel = _sessionArray[indexPath.section];
    NSArray *array = categoryModel.categoryValue;
    PLConfigureModel *configureModel = array[indexPath.row];
    NSArray *rowArray = configureModel.configuraValue;
    
    if ((rowArray.count <= 7 && [rowArray[0] length] < 6) || (rowArray.count <= 3 && [rowArray[1] length] < 14)) {
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLCategoryModel *categoryModel = _sessionArray[indexPath.section];
    NSArray *array = categoryModel.categoryValue;
    PLConfigureModel *configureModel = array[indexPath.row];
    NSArray *rowArray = configureModel.configuraValue;
    if ((rowArray.count <= 7 && [rowArray[0] length] < 6) || (rowArray.count <= 3 && [rowArray[1] length] < 14)) {
        return [PLSegmentTableViewCell configureSegmentCellHeightWithString:configureModel.configuraKey];
    } else{
        return [PLListArrTableViewCell configureListArrayCellHeightWithString:configureModel.configuraKey];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, KSCREEN_WIDTH, 40)];
    headerView.backgroundColor = [UIColor whiteColor];
    PLCategoryModel *categoryModel = _sessionArray[section];
    UILabel *headLab = [[UILabel alloc]initWithFrame:CGRectMake(20, 5, KSCREEN_WIDTH - 40, 30)];
    headLab.font = FONT_MEDIUM(15);
    headLab.textAlignment = NSTextAlignmentLeft;
    headLab.text = [NSString stringWithFormat:@">>> %@", categoryModel.categoryKey];
    [headerView addSubview:headLab];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0f;
}

# pragma mark ---- segment action ----
- (void)segmentAction:(UISegmentedControl *)segment {
    NSInteger section = segment.tag / 100;
    NSInteger row = segment.tag % 100;
    PLCategoryModel *categoryModel = _sessionArray[section];
    NSArray *array = categoryModel.categoryValue;
    PLConfigureModel *configureModel = array[row];
    
    [self controlPropertiesWithIndex:segment.selectedSegmentIndex configureModel:configureModel categoryModel:categoryModel];
}

# pragma mark ---- listButton action ----
- (void)listButtonAction:(UIButton *)listButton {
    NSInteger section = listButton.tag / 100;
    NSInteger row = listButton.tag % 100;
    PLCategoryModel *categoryModel = _sessionArray[section];
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
- (void)listArrayViewSelectedWithIndex:(NSInteger)index configureModel:(PLConfigureModel *)configureModel categoryModel:(PLCategoryModel *)categoryModel {
    [self controlPropertiesWithIndex:index configureModel:configureModel categoryModel:categoryModel];
}

# pragma mark ---- 是否图片推流 是否禁止操作视频相关属性 ----
- (void)controlPropertiesWithIndex:(NSInteger)index configureModel:(PLConfigureModel *)configureModel categoryModel:(PLCategoryModel *)categoryModel {
    configureModel.selectedNum = [NSNumber numberWithInteger:index];
    [_sessionTableView reloadData];
    [self saveSessions];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(configureSessionWithConfigureModel:categoryModel:)]) {
        [self.delegate configureSessionWithConfigureModel:configureModel categoryModel:categoryModel];
        [self dismissView];
    }
}

- (void)dismissView{
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark ---- 数据本地化 ----
- (void)saveSessions{
    NSMutableArray *dataArr = [NSMutableArray array];
    for (PLCategoryModel * categoryModel in _sessionArray) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:categoryModel];
        [dataArr addObject:data];
    }
    NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
    [userdafault setObject:[NSArray arrayWithArray:dataArr] forKey:@"session"];
    [userdafault synchronize];
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
