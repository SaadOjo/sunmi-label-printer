//
//  PrinterSettingEntranceController.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/15.
//

#import "PrinterSettingEntranceController.h"
#import "PrinterSearchingController.h"

@interface PrinterSettingEntranceController ()

// addRouterImage
@property (nonatomic, strong) NSImageView *deviceImage;
// titleLabel
@property (nonatomic, strong) NSTextField *titleLabel;
// tip1
@property (nonatomic, strong) NSTextField *tip1;
// tip2
@property (nonatomic, strong) NSTextField *tip2;
// tip3
@property (nonatomic, strong) NSTextField *tip3;
// 开始设置按钮
@property (nonatomic, strong) SYFlatButton *startBtn;

@end

@implementation PrinterSettingEntranceController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Setup Printer";
    
    [self setupUI];
}

- (void)setupUI {
    [self.view addSubview:self.deviceImage];
    [self.deviceImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.offset(15);
        make.width.offset(200);
        make.height.offset(200);
    }];
    
    // titleLabel
    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.deviceImage.mas_bottom).offset(15.0f);
        make.centerX.offset(0);
        make.size.mas_equalTo(CGSizeMake(500, 30));
    }];
    
    // tip1
    [self.view addSubview:self.tip1];
    [self.tip1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(15.0f);
        make.size.mas_equalTo(CGSizeMake(500, 18));
    }];
    
    // tip2
    [self.view addSubview:self.tip2];
    [self.tip2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.equalTo(self.tip1.mas_bottom).offset(15.0f);
        make.size.mas_equalTo(CGSizeMake(500, 18));
    }];
    
    // tip3
    [self.view addSubview:self.tip3];
    [self.tip3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.equalTo(self.tip2.mas_bottom).offset(15.0f);
        make.size.mas_equalTo(CGSizeMake(500, 35));
    }];
    
    // 开始设置按钮
    [self.view addSubview:self.startBtn];
    [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.bottom.offset(-40);
        make.size.mas_equalTo(CGSizeMake(500, 44));
    }];
}

// 开始设置
- (void)clickStartBtn {
    PrinterSearchingController *vc = [[PrinterSearchingController alloc] init];
    [self presentViewControllerAsModalWindow:vc];
}


#pragma mark - getter
- (NSImageView *)deviceImage {
    if (!_deviceImage) {
        _deviceImage = [[NSImageView alloc] init];
        _deviceImage.image = [NSImage imageNamed:@"printer_set_entrance"];
    }
    return _deviceImage;
}

- (NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NSTextField alloc] init];
        _titleLabel.editable = NO;
        _titleLabel.bordered = NO;
        _titleLabel.backgroundColor = [NSColor clearColor];
        _titleLabel.textColor = COLOR_33;
        _titleLabel.maximumNumberOfLines = 0;
        _titleLabel.stringValue = @"Prepare to set up the Cloud Printer";
        _titleLabel.font = [NSFont systemFontOfSize:24];
        _titleLabel.alignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (NSTextField *)tip1 {
    if (!_tip1) {
        _tip1 = [[NSTextField alloc] init];
        _tip1.editable = NO;
        _tip1.bordered = NO;
        _tip1.stringValue = @"1. Turn on the cloud printer, press and hold the button displayed in the figure for more than 3 seconds.";
        _tip1.textColor = COLOR_33;
        _tip1.backgroundColor = [NSColor clearColor];
        _tip1.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
        _tip1.maximumNumberOfLines = 0;
    }
    return _tip1;
}

- (NSTextField *)tip2 {
    if (!_tip2) {
        _tip2 = [[NSTextField alloc] init];
        _tip2.editable = NO;
        _tip2.bordered = NO;
        _tip2.stringValue = @"2. until you hear the voice prompt before releasing it.";
        _tip2.textColor = COLOR_33;
        _tip2.backgroundColor = [NSColor clearColor];
        _tip2.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
        _tip2.maximumNumberOfLines = 0;
    }
    return _tip2;
}

- (NSTextField *)tip3 {
    if (!_tip3) {
        _tip3 = [[NSTextField alloc] init];
        _tip3.editable = NO;
        _tip3.bordered = NO;
        _tip3.backgroundColor = [NSColor clearColor];
        NSString *allStr = @"3. Click the \"START\" button below and select the Cloud Printer \n (please make sure that the Bluetooth of your phone is turned on).";
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:allStr];
        [string addAttributes:@{NSForegroundColorAttributeName: COLOR_33,
                                NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightMedium]}
                        range:NSMakeRange(0, allStr.length)];
        NSRange rang = [allStr rangeOfString:@"(please make sure that the Bluetooth of your phone is turned on)"];
        [string addAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
                                NSForegroundColorAttributeName:COLOR_77} range:rang];
        
        _tip3.attributedStringValue = string;
        _tip3.maximumNumberOfLines = 0;
    }
    return _tip3;
}

- (NSButton *)startBtn {
    if (!_startBtn) {
        _startBtn = [[SYFlatButton alloc] init];
        _startBtn.title = @"Start";
        _startBtn.momentary = YES;
        
        _startBtn.cornerRadius = 22;
        _startBtn.titleNormalColor = [NSColor whiteColor];
        _startBtn.titleHighlightColor = [NSColor whiteColor];
        _startBtn.backgroundNormalColor = SM_COLORHEX(0xFF6000,1);
        _startBtn.backgroundHighlightColor = SM_COLORHEX(0xFF6000,1);
        
        [_startBtn setTarget:self];
        [_startBtn setAction:@selector(clickStartBtn)];
    }
    return _startBtn;
}

@end
