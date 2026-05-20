//
//  PrinterSearchingController.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/15.
//

#import "PrinterSearchingController.h"
#import "PrinterWifiListController.h"
#import "SMTableViewCell.h"

@interface PrinterSearchingController ()<PrinterManagerDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) SunmiPrinterManager *bleManager;

@property (nonatomic, strong) NSScrollView *mainScrollView;
@property (nonatomic, strong) NSTableView *tableView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) NSMutableArray *bleDeviceNames;

@property (nonatomic, strong) dispatch_source_t timeoutTimer;

@property (nonatomic, strong) EmptyRefreshView *refreshView;

@property (nonatomic, strong) SMIndicator *indicatorView;

@end

@implementation PrinterSearchingController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.title = @"Search Printer";
    
    [self addTableView];
    
    [self addRefreshView];
    
    [self addIndicatorView];
}

- (void)addTableView {
    self.mainScrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.tableView = [[NSTableView alloc] initWithFrame:CGRectMake(0, 40, self.view.bounds.size.width, self.view.bounds.size.height - 40)];
    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"search_printer"];
    [column1 setWidth:self.view.bounds.size.width];
    [_tableView addTableColumn:column1];//第一列
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.allowsColumnReordering = NO;
    self.tableView.allowsColumnResizing = NO;
    self.tableView.focusRingType = NSFocusRingTypeNone;
    
    self.tableView.headerView = nil;
    self.tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
    self.tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    
    [self.mainScrollView.contentView setDocumentView:_tableView];
    [self.view addSubview:self.mainScrollView];
}

- (void)addRefreshView {
    [self.view addSubview:self.refreshView];
    [self.refreshView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.equalTo(self.view).offset(100);
        make.size.mas_equalTo(CGSizeMake(500, 500));
    }];
}

- (void)addIndicatorView {
    self.indicatorView = [[SMIndicator alloc] init];
    [self.view addSubview:self.indicatorView];
    [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(120, 120));
    }];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    
    [self initialBleManager];
    [self startSearchingState];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    
    _bleManager.bluetoothDelegate = nil;
    [self.bleDeviceNames removeAllObjects];
}

- (void)initialBleManager {
    //开始搜索蓝牙外设
    _bleManager = [SunmiPrinterManager shareInstance];
    [_bleManager setDeviceSearchState:YES];
    _bleManager.bluetoothDelegate = self;
    [_bleManager searchCloudPrinter];
}

#pragma mark -------------------------- BluetoothManagerDelegate
- (void)discoveredDevice:(SunmiBlePrinterModel *_Nonnull)device {
    //根据名称过滤
    if (![self.bleDeviceNames containsObject:device.deviceName]) {
        [self.bleDeviceNames addObject:device.deviceName];
        [self.dataSource addObject:device];
        
        [self.tableView reloadData];
    }
}

- (void)didEnterNetworkMode {
    [self nextWifiSettigPage];
}

- (void)didConectPrinter {
    [self.indicatorView dismiss];
    [self stopConnectBLETimer];
    if (enterNetworkModeCommand) {
        SunmiPrinterCommand *command = [[SunmiPrinterCommand alloc] init];
        [command clearBuffer];
        [command getDeviceSN];
        NSData *data = [command getCommandData];
        [[SunmiPrinterManager shareInstance] sendPrintData:data];
        [[SunmiPrinterManager shareInstance] receivedDeviceData:^(NSString * _Nullable deviceSN, SMPrinterStatus printerStatus, NSString * _Nullable taskNumber) {
            NSLog(@"%@-%ld-%@", deviceSN, printerStatus, taskNumber);
            if (deviceSN) {
                [self.bleManager startPrinterWifi:deviceSN];
            }
        }];
    }
    else {
        [self nextWifiSettigPage];
    }
}

- (void)didFinishedSearching {
    __weak __typeof(&*self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf updateViewShowOrHidden];
    });
}

- (void)willDisconnectPrinter {
    [self.indicatorView dismiss];
    [self alertWithMessage:@"Device Bluetooth connection failed"];
}

-(void)alertWithMessage:(NSString *)message {
    [self.indicatorView dismiss];
    
    SMAlert *alert = [SMAlert alertWithTitle:@"" message:message style:NSAlertStyleWarning];
    [alert addCommonButtonWithTitle:@"ok" handler:^(SMAlertItem * _Nonnull item) {
        [self dismissViewController:self];
    }];
    
    [alert show:self.view.window];
}

- (void)nextWifiSettigPage {
    PrinterWifiListController *vc = [PrinterWifiListController new];
    [self presentViewControllerAsModalWindow:vc];
}

#pragma mark -------------------------- 界面状态
//开始搜寻打印机设备
- (void)startSearchingState {
    if (self.dataSource.count) {
        [self.dataSource removeAllObjects];
        [self.bleDeviceNames removeAllObjects];
    }
    [self.tableView reloadData];
}

//搜索结束
- (void)stopSearchingState {
    [self updateViewShowOrHidden];
}

- (void)updateViewShowOrHidden  {
    if (self.dataSource.count > 0) {
        [self hasDevices];
        [self.tableView reloadData];
    }
    else {
        [self noDeviceFound];
    }
}

- (void)hasDevices {
    self.mainScrollView.hidden = NO;
    self.refreshView.hidden = YES;
}

//没有搜索到设备
- (void)noDeviceFound {
    self.mainScrollView.hidden = YES;
    self.refreshView.hidden = NO;
}

//刷新重新寻找设备
- (void)refreshButtonTapped {
    [self hasDevices];
    [self startSearchingState];
    [_bleManager searchCloudPrinter];
}

//连接蓝牙超时
- (void)startConnectBLETimer {
    __block int timeout = 30.0;
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timeoutTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, global);
    dispatch_source_set_timer(_timeoutTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    __weak __typeof(&*self)weakSelf = self;
    dispatch_source_set_event_handler(_timeoutTimer, ^{
        timeout --;
        if (timeout == 0) {
            dispatch_source_cancel(weakSelf.timeoutTimer);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.indicatorView dismiss];
                [self alertWithMessage:@"Device Bluetooth connection failed"];
            });
        }
    });
    dispatch_resume(_timeoutTimer);
}

- (void)stopConnectBLETimer {
    if (_timeoutTimer) {
        dispatch_source_cancel(_timeoutTimer);
        dispatch_cancel(_timeoutTimer);
        _timeoutTimer = nil;
    }
}

#pragma mark - getter
- (EmptyRefreshView *)refreshView {
    if (!_refreshView) {
        _refreshView = [[EmptyRefreshView alloc] init];
        [_refreshView setLogo:@"sunmi_printer"];
        [_refreshView setTip_up:@"No Cloud Printer found"];
        [_refreshView setTip_down:@"No cloud printer found, please confirm if the match button has been long pressed, then refresh and try again. (Please make sure the phone Bluetooth is turned on)."];
        __weak typeof(self)weakSelf = self;
        _refreshView.refreshBlock = ^{
            [weakSelf refreshButtonTapped];
        };
        _refreshView.hidden = YES;
    }
    return _refreshView;
}

- (NSMutableArray *)bleDeviceNames {
    if (!_bleDeviceNames) {
        _bleDeviceNames = [NSMutableArray new];
    }
    return _bleDeviceNames;
}
- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc] init];
    }
    return _dataSource;
}


#pragma mark - NSTableViewDelegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.dataSource.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 50;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SMTableViewCell *cell = [[SMTableViewCell alloc] initWithFrame:NSMakeRect(0, 0, self.view.bounds.size.width, 50)];
    if ([[tableColumn identifier] isEqualToString:@"search_printer"]) {
        if (self.dataSource.count > 0) {
            SunmiBlePrinterModel *model = self.dataSource[row];
            cell.deviceNameString = model.deviceName;
        }
    }
    
    return cell;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    NSTableRowView *rowView = [[NSTableRowView alloc] init];
    rowView.emphasized = NO;
    return rowView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    if (tableView.selectedRow >= 0) {
        SunmiBlePrinterModel *model = self.dataSource[tableView.selectedRow];
        CBPeripheral *peripheral = model.peripheral;
        [_bleManager connectPeripheral:peripheral];
        [self startConnectBLETimer];
        [self.indicatorView show];
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}

@end
