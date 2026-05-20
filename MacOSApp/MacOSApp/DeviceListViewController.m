//
//  DeviceListViewController.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/15.
//

#import "DeviceListViewController.h"
#import "SMTableViewCell.h"

@interface DeviceListViewController ()<IPPrinterManagerDelegate, PrinterManagerDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) SunmiPrinterManager *bleManager;
@property (nonatomic, strong) SunmiPrinterIPManager *ipManager;

@property(nonatomic, strong)NSMutableArray <SunmiBlePrinterModel *> *bleDataSource;
@property(nonatomic, strong)NSMutableArray <SunmiIpPrinterModel *> *ipDataSource;

@property (nonatomic, strong) NSScrollView *mainScrollView;
@property (nonatomic, strong) NSTableView *tableView;

@property (nonatomic, strong) SunmiBlePrinterModel *connectModel;

@property (nonatomic, strong) SYFlatButton *refreshButton;
@property (nonatomic, strong) SMIndicator *indicatorView;

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Printer list";
    
    self.ipDataSource = [[NSMutableArray alloc] init];
    
    [self addTableView];
    [self addRefreshButton];
    [self addIndicatorView];
    
    if (self.printType) {
        _ipManager = [SunmiPrinterIPManager sharedManager];
        _ipManager.delegate = self;
        [self searchIpDevice];
    }
    else {
        _bleManager = [SunmiPrinterManager shareInstance];
        [_bleManager setDeviceSearchState:YES];
        _bleManager.bluetoothDelegate = self;
        
        [self searchDevice];
    }
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    
    _bleManager.bluetoothDelegate = nil;
    self.connectModel = nil;
}

- (void)addTableView {
    self.mainScrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.tableView = [[NSTableView alloc] initWithFrame:CGRectMake(0, 40, self.view.bounds.size.width, self.view.bounds.size.height - 40)];
    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"firstColumn"];
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

- (void)addRefreshButton {
    [self.view addSubview:self.refreshButton];
    [self.refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.offset(0);
        make.size.mas_equalTo(CGSizeMake(104, 36));
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

#pragma mark - NSTableViewDelegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.printType == PrintConnectIP ? self.ipDataSource.count : self.bleDataSource.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 50;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SMTableViewCell *cell = [[SMTableViewCell alloc] initWithFrame:NSMakeRect(0, 0, self.view.bounds.size.width, 50)];
    if ([[tableColumn identifier] isEqualToString:@"firstColumn"]) {
        if (self.printType == PrintConnectIP && self.ipDataSource.count > 0) {
            SunmiIpPrinterModel *model = self.ipDataSource[row];
            cell.deviceNameString = model.deviceName;
        }
        else if (self.printType == PrintConnectBluetooth && self.bleDataSource.count > 0) {
            SunmiBlePrinterModel *model = self.bleDataSource[row];
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
        if (self.printType) {
            __weak typeof(self)weakSelf = self;
            SunmiIpPrinterModel *model = self.ipDataSource[tableView.selectedRow];
            [self.indicatorView show];
            [[SunmiPrinterIPManager sharedManager] connectSocketWithIP:model.deviceIP completeBlock:^(NSError *err) {
                [self.indicatorView dismiss];
                if (err) {
                    NSLog(@"失败了:%@", err.description);
                }
                else {
                    [weakSelf.tableView reloadData];
                    if (weakSelf.connectedIPStatusBlock) {
                        weakSelf.connectedIPStatusBlock(model, weakSelf.printType);
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self dismissViewController:self];
                    });
                }
            }];
        }
        else {
            SunmiBlePrinterModel *model = self.bleDataSource[tableView.selectedRow];
            self.connectModel = model;
            [self.indicatorView show];
            [[SunmiPrinterManager shareInstance] connectPeripheral:model.peripheral];
        }
    }
}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}

#pragma mark - PrinterManagerDelegate
- (void)searchDevice {
    [self.indicatorView show];
    [self.bleDataSource removeAllObjects];
    [[SunmiPrinterManager shareInstance] searchCloudPrinter];
}

- (void)discoveredDevice:(SunmiBlePrinterModel *_Nonnull)device {
    NSLog(@"搜索到设备%@", device.deviceName);
    BOOL isExist = NO;
    for (SunmiBlePrinterModel * m in self.bleDataSource) {
        if ([m.deviceName isEqualToString:device.deviceName]) {
            isExist = YES;
            break;
        }
    }
    
    if (!isExist) {
        [self.bleDataSource addObject:device];
    }
    
    [self.tableView reloadData];
}

- (void)didFinishedSearching {
    [self.indicatorView dismiss];
    [self updateTableView];
}

- (void)didConectPrinter {
    [self.indicatorView dismiss];
    if (self.connectedStatusBlock) {
        self.connectedStatusBlock(self.connectModel, self.printType);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewController:self];
    });
}

#pragma mark - IPPrinterManagerDelegate

- (void)searchIpDevice {
    [self.indicatorView show];
    [self.ipDataSource removeAllObjects];
    [[SunmiPrinterIPManager sharedManager] startSearchPrinterWithIp:nil];
}

- (void)discoverIPPrinter:(SunmiIpPrinterModel * _Nullable)printerModel {
    NSLog(@"搜索到设备%@", printerModel.deviceName);
    BOOL isExist = NO;
    for (SunmiIpPrinterModel * m in self.ipDataSource) {
        if ([m.deviceSN isEqualToString:printerModel.deviceSN]) {
            isExist = YES;
            break;
        }
    }
    
    if (!isExist) {
        [self.ipDataSource addObject:printerModel];
    }
    
    [self.tableView reloadData];
}

- (void)finshedSearchPrinter {
    [self.indicatorView dismiss];
    [self updateTableView];
}

- (void)updateTableView {
    if (self.bleDataSource.count > 0 || self.ipDataSource.count > 0) {
        self.mainScrollView.hidden = NO;
        self.refreshButton.hidden = YES;
    }
    else {
        self.mainScrollView.hidden = YES;
        self.refreshButton.hidden = NO;
    }
    [self.tableView reloadData];
}

#pragma mark - getter
- (NSMutableArray *)bleDataSource {
    if (_bleDataSource == nil) {
        _bleDataSource = [[NSMutableArray alloc]init];
    }
    return _bleDataSource;
}

- (NSMutableArray *)ipDataSource {
    if (_ipDataSource == nil) {
        _ipDataSource = [[NSMutableArray alloc]init];
    }
    return _ipDataSource;
}

- (SYFlatButton *)refreshButton {
    if (!_refreshButton) {
        _refreshButton = [[SYFlatButton alloc] init];
        _refreshButton.hidden = YES;
        _refreshButton.title = @"Refresh";
        _refreshButton.momentary = YES;
        
        _refreshButton.borderWidth = 0.5;
        _refreshButton.borderNormalColor = SM_COLORHEX(0xA1A7B3,1);
        _refreshButton.borderHighlightColor = SM_COLORHEX(0xA1A7B3,1);
        
        _refreshButton.cornerRadius = 18;
        _refreshButton.titleNormalColor = SM_COLORHEX(0x525866,1);
        _refreshButton.titleHighlightColor = SM_COLORHEX(0x525866,1);
        _refreshButton.backgroundNormalColor = [NSColor whiteColor];
        _refreshButton.backgroundHighlightColor = [NSColor whiteColor];
        
        [_refreshButton setTarget:self];
        [_refreshButton setAction:@selector(refreshButtonclick)];
    }
    return _refreshButton;
}

//刷新重新寻找设备
- (void)refreshButtonclick {
    self.mainScrollView.hidden = NO;
    self.refreshButton.hidden = YES;
    if (self.printType) {
        [self.ipDataSource removeAllObjects];
        [self.tableView reloadData];
        [self searchIpDevice];
    }
    else {
        [self.bleDataSource removeAllObjects];
        [self.tableView reloadData];
        [self searchDevice];
    }
}

@end
