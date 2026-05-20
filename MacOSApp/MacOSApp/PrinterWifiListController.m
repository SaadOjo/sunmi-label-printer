//
//  PrinterWifiListController.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/15.
//

#import "PrinterWifiListController.h"
#import "CustomTableCellView.h"

@interface PrinterWifiListController ()<NSTableViewDelegate, NSTableViewDataSource, PrinterManagerDelegate>

@property (nonatomic, strong) NSScrollView *mainScrollView;
@property (nonatomic, strong) NSTableView *tableView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic,assign) BOOL noAlert;

@property (nonatomic,strong) SunmiPrinterManager *bleManager;

//获取Wi-Fi列表超时
@property (nonatomic,strong) dispatch_source_t wifiListTimer;
//连接Wi-Fi超时
@property (nonatomic,strong) dispatch_source_t connectWifiTimer;

@property (nonatomic, strong) EmptyRefreshView *refreshView;
@property (nonatomic, strong) SMIndicator *indicatorView;

@property (nonatomic, strong) SMInput *inputBox;

@end

@implementation PrinterWifiListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Printer Wi-Fi";
    
    [self addTableView];
    [self addRefreshView];
    [self addIndicatorView];
}

- (void)exitController {
    [self.bleManager exitPrinterWifiSetting];
    [self dismissViewController:self];
}

- (void)addTableView {
    self.mainScrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.tableView = [[NSTableView alloc] initWithFrame:CGRectMake(0, 40, self.view.bounds.size.width, self.view.bounds.size.height - 40)];
    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"printer_wifi"];
    [column1 setWidth:self.view.bounds.size.width];
    [_tableView addTableColumn:column1];//第一列
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.allowsColumnReordering = NO;
    self.tableView.allowsColumnResizing = NO;
    self.tableView.focusRingType = NSFocusRingTypeNone;
    
    self.tableView.headerView.frame = NSZeroRect;
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
    
    _bleManager = [SunmiPrinterManager shareInstance];
    _bleManager.bluetoothDelegate = self;
    [self.indicatorView show];
    [_bleManager searchPrinterWifiList];
    [self startWifiListTimer];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    
    _bleManager.bluetoothDelegate = nil;
    [SunmiPrinterManager instanceDealloc];
    _bleManager = nil;
}

- (void)refreshTable {
    if (self.dataSource.count) {
        self.mainScrollView.hidden = NO;
        self.refreshView.hidden = YES;
        
        [self.tableView reloadData];
    }
    else {
        self.mainScrollView.hidden = YES;
        self.refreshView.hidden = NO;
    }
}

#pragma mark ---------------------- BluetoothManagerDelegate
//接收wifi信息失败
- (void)didFailedToReceiveWifiInformation {
    NSLog(@"接收Wi-Fi信息失败");
    [self refreshTable];
}

//接收到的Wi-Fi信息
- (void)receiveAPInfo:(NSDictionary *)wifiInfo {
    NSLog(@"接收Wi-Fi数据-%@", wifiInfo);
    [self stopWifiListTimer];
    //加载Wi-Fi
    [self.indicatorView dismiss];
    [self.dataSource addObject:wifiInfo];
    [self refreshTable];
}

//接收Wi-Fi列表完毕
- (void)didReceivedWifiListCompleted{
    NSLog(@"接收Wi-Fi列表完毕");
}

//开始设置Wi-Fi
- (void)willStartConfigPrinterWifi{
    NSLog(@"开始设置Wi-Fi");
}

//设置Wi-Fi成功
- (void)configPrinterWifiSuccessed {
    //接收到连接成功的消息后，断开蓝牙不再弹提示框
    self.noAlert = YES;
    //loading弹框消失
    [self.indicatorView dismiss];
    [self stopConnectWifiTimer];
    [self.bleManager connectAPSuccess];
    NSLog(@"设置Wi-Fi成功");
    [self exitController];
//    [SunmiProgressHUD toastWithText:@"Wi-Fi Success"];
}

//设置Wi-Fi失败
- (void)configPrinterWifiFailed {
    NSLog(@"设置Wi-Fi失败");
    [self alertWithMessage:@"Failed to connect to the Wi-Fi, please check the password and try again"];
    [self stopConnectWifiTimer];
}

- (void)willDisconnectPrinter {
    if (!self.noAlert) {
        [self alertWithMessage:@"Device Bluetooth connection failed"];
        [self.indicatorView dismiss];
    }
}

- (void)alertWithMessage:(NSString *)message {
    [self.indicatorView dismiss];
    
    SMAlert *alert = [SMAlert alertWithTitle:@"" message:message style:NSAlertStyleWarning];
    [alert addCommonButtonWithTitle:@"ok" handler:^(SMAlertItem * _Nonnull item) {
        [self dismissViewController:self];
    }];
    
    [alert show:self.view.window];
}

- (void)connectWifiFailAlert {
    SMAlert *alert = [SMAlert alertWithTitle:@"Warnning" message:@"Failed to get the device Wi-Fi connection information. Please confirm whether to reconnect." style:NSAlertStyleWarning];
    [alert addCommonButtonWithTitle:@"OK" handler:^(SMAlertItem * _Nonnull item) {
        
    }];
    
    [alert addCommonButtonWithTitle:@"Cancel" handler:^(SMAlertItem * _Nonnull item) {
        [self dismissViewController:self];
    }];
    
    [alert show:self.view.window];
}

#pragma mark - NSTableViewDelegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.dataSource.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 50;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CustomTableCellView *cell = [[CustomTableCellView alloc] initWithFrame:NSMakeRect(0, 0, self.view.bounds.size.width, 50)];
    if ([[tableColumn identifier] isEqualToString:@"printer_wifi"]) {
        if (self.dataSource.count > 0) {
            NSDictionary *cellDic = self.dataSource[row];
            NSString *ssid = [NSString stringWithFormat:@"%@", cellDic[@"ssid"]];
            BOOL encrypt = [cellDic[@"authMode"] boolValue];
            NSString *rssi = [NSString stringWithFormat:@"%@", cellDic[@"rssi"]];
            [cell wifiName:ssid withPassword:encrypt rssi:rssi];
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
        NSDictionary *rowDic = self.dataSource[tableView.selectedRow];
        BOOL hasPassword = [rowDic[@"authMode"] boolValue];
        NSString *ssidstring = rowDic[@"ssid"];
        if (hasPassword) {
            if (!self.inputBox) {
                self.inputBox = [[SMInput alloc] initWithTitle:@"Password" message:@"" style:NSAlertStyleWarning];
            }
            __weak __typeof(&*self)weakSelf = self;
            [self.inputBox show:self.view.window handler:^(SMInput * _Nonnull item) {
                NSString *passwordstring = item.textFieldString;
                [weakSelf.bleManager setPrinterWifi:ssidstring password:passwordstring];
                [weakSelf.indicatorView show];
                [weakSelf startConnectWifiTimer];
            }];
        }
        else {
            SMAlert *alert = [SMAlert alertWithTitle:@"" message:[NSString stringWithFormat:@"Whether connect to \"%@\"", ssidstring] style:NSAlertStyleWarning];
            [alert addCommonButtonWithTitle:@"ok" handler:^(SMAlertItem * _Nonnull item) {
                [self.bleManager setPrinterWifi:ssidstring password:nil];
                [self.indicatorView show];
                [self startConnectWifiTimer];
            }];
            
            [alert show:self.view.window];
        }
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}

//获取Wi-Fi列表超时的timer
- (void)startWifiListTimer {
    __block int timeout = 30.0;
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _wifiListTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, global);
    dispatch_source_set_timer(_wifiListTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    __weak __typeof(&*self)weakSelf = self;
    dispatch_source_set_event_handler(_wifiListTimer, ^{
        timeout --;
        if (timeout == 0) {
            dispatch_source_cancel(weakSelf.wifiListTimer);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshTable];
                [self.indicatorView dismiss];
            });
        }
    });
    dispatch_resume(_wifiListTimer);
}

- (void)stopWifiListTimer {
    if (_wifiListTimer) {
        dispatch_source_cancel(_wifiListTimer);
        dispatch_cancel(_wifiListTimer);
        _wifiListTimer = nil;
    }
}

//连接Wi-Fi超时的timer
- (void)startConnectWifiTimer {
    __block int timeout = 30.0;
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _connectWifiTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, global);
    dispatch_source_set_timer(_connectWifiTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    __weak __typeof(&*self)weakSelf = self;
    dispatch_source_set_event_handler(_connectWifiTimer, ^{
        timeout --;
        if (timeout == 0) {
            dispatch_source_cancel(weakSelf.connectWifiTimer);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self connectWifiFailAlert];
                [self.indicatorView dismiss];
            });
        }
    });
    dispatch_resume(_connectWifiTimer);
}

- (void)stopConnectWifiTimer {
    if (_connectWifiTimer) {
        dispatch_source_cancel(_connectWifiTimer);
        dispatch_cancel(_connectWifiTimer);
        _connectWifiTimer = nil;
    }
}

#pragma mark - getter
- (EmptyRefreshView *)refreshView {
    if (!_refreshView) {
        _refreshView = [[EmptyRefreshView alloc] init];
        [_refreshView setLogo:@"no_wifi_found"];
        [_refreshView setTip_up:@"No available Wi-Fi"];
        [_refreshView setTip_down:@"Please check the network and retry"];
        __weak typeof(self)weakSelf = self;
        _refreshView.refreshBlock = ^{
            [weakSelf refreshButtonTapped];
        };
        _refreshView.hidden = YES;
    }
    return _refreshView;
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc] init];
    }
    return _dataSource;
}

- (void)refreshButtonTapped {
    [self.dataSource removeAllObjects];
    self.mainScrollView.hidden = NO;
    self.refreshView.hidden = YES;
    [self.tableView reloadData];
    
    [self.indicatorView show];
    [self.bleManager searchPrinterWifiList];
    [self startWifiListTimer];
}

@end
