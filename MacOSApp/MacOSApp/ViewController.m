//
//  ViewController.m
//  MacOSApp
//
//  Production-oriented SUNMI print studio UI: connection, receipts, labels,
//  and a first label-designer workflow.
//

#import "ViewController.h"
#import "DeviceListViewController.h"
#import "PrinterSearchingController.h"
#import "PrinterSettingEntranceController.h"
#import "LabelPrinting/SMLabelCommandBuilder.h"
#import "LabelPrinting/SMLabelContent.h"
#import "LabelPrinting/SMLabelPrintSettings.h"
#import "PrinterConnection/SMPrinterConnection.h"
#import "ReceiptPrinting/SMReceiptCommandBuilder.h"
#import "ReceiptPrinting/SMReceiptContent.h"
#import "ReceiptPrinting/SMReceiptPrintSettings.h"
#import "LabelDesigner/SMLabelDesignerCanvasView.h"
#import "LabelDesigner/SMLabelRasterCommandBuilder.h"

typedef NS_ENUM(NSInteger, SMAppSection) {
    SMAppSectionConnect = 0,
    SMAppSectionReceipt,
    SMAppSectionLabels,
    SMAppSectionDesigner
};

@interface ViewController () <SMLabelDesignerCanvasViewDelegate>

@property (nonatomic, strong) SMPrinterConnection *connection;
@property (nonatomic, assign) BOOL didConfigureWindow;
@property (nonatomic, assign) SMAppSection currentSection;

@property (nonatomic, strong) NSView *contentContainer;
@property (nonatomic, strong) NSTextField *sectionTitleLabel;
@property (nonatomic, strong) NSTextField *sectionSubtitleLabel;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSButton *> *sidebarButtons;

@property (nonatomic, strong) NSView *connectionPage;
@property (nonatomic, strong) NSTextField *connectionSummaryLabel;
@property (nonatomic, strong) NSTextField *manualIPField;

@property (nonatomic, strong) NSView *receiptPage;
@property (nonatomic, strong) NSPopUpButton *receiptWidthPopup;
@property (nonatomic, strong) NSTextField *receiptDensityField;
@property (nonatomic, strong) NSTextField *receiptSpeedField;
@property (nonatomic, strong) NSButton *receiptLogoButton;
@property (nonatomic, strong) NSButton *receiptCutButton;
@property (nonatomic, strong) NSButton *receiptCashDrawerButton;
@property (nonatomic, strong) NSTextField *receiptStoreField;
@property (nonatomic, strong) NSTextField *receiptAddressField;
@property (nonatomic, strong) NSTextField *receiptPhoneField;
@property (nonatomic, strong) NSTextField *receiptOrderField;
@property (nonatomic, strong) NSTextField *receiptCashierField;
@property (nonatomic, strong) NSTextField *receiptFooterField;
@property (nonatomic, strong) NSTextField *receiptBarcodeField;
@property (nonatomic, strong) NSTextField *receiptQRField;
@property (nonatomic, strong) NSImageView *receiptPreviewImageView;

@property (nonatomic, strong) NSView *labelPage;
@property (nonatomic, strong) NSTextField *widthField;
@property (nonatomic, strong) NSTextField *heightField;
@property (nonatomic, strong) NSTextField *gapField;
@property (nonatomic, strong) NSTextField *speedField;
@property (nonatomic, strong) NSTextField *densityField;
@property (nonatomic, strong) NSTextField *brandField;
@property (nonatomic, strong) NSTextField *productField;
@property (nonatomic, strong) NSTextField *skuField;
@property (nonatomic, strong) NSTextField *priceField;
@property (nonatomic, strong) NSTextField *qrField;
@property (nonatomic, strong) NSTextView *labelPreviewTextView;

@property (nonatomic, strong) NSView *designerPage;
@property (nonatomic, strong) NSTextField *designerWidthField;
@property (nonatomic, strong) NSTextField *designerHeightField;
@property (nonatomic, strong) NSTextField *designerGapField;
@property (nonatomic, strong) NSPopUpButton *designerPresetPopup;
@property (nonatomic, strong) NSTextField *designerDensityField;
@property (nonatomic, strong) SMLabelDesignerCanvasView *designerCanvasView;
@property (nonatomic, strong) NSTextField *designerElementTextField;
@property (nonatomic, strong) NSTextField *designerXField;
@property (nonatomic, strong) NSTextField *designerYField;
@property (nonatomic, strong) NSTextField *designerWField;
@property (nonatomic, strong) NSTextField *designerHField;
@property (nonatomic, strong) NSPopUpButton *designerFontPopup;
@property (nonatomic, strong) NSTextField *designerFontSizeField;
@property (nonatomic, strong) NSButton *designerBoldButton;
@property (nonatomic, strong) NSPopUpButton *designerAlignPopup;
@property (nonatomic, strong) NSButton *designerGridButton;
@property (nonatomic, strong) NSTextView *designerPreviewTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = NSMakeSize(980, 720);
    self.connection = [[SMPrinterConnection alloc] init];
    self.sidebarButtons = [NSMutableDictionary dictionary];
    [self setupConnectionCallbacks];
    [self setupUI];
    [self showSection:SMAppSectionConnect];
    [self updateConnectionStatus:@"No printer connected. Connect via LAN, USB, or Bluetooth to start printing."];
    [self refreshReceiptPreview:nil];
    [self refreshLabelPreview:nil];
    [self refreshDesignerPreview:nil];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    if (self.didConfigureWindow) {
        return;
    }
    self.didConfigureWindow = YES;
    NSWindow *window = self.view.window;
    window.title = @"OJO Print Studio";
    window.minSize = NSMakeSize(980, 720);
    [window setContentSize:NSMakeSize(980, 720)];
    [window center];
}

#pragma mark - App shell

- (void)setupUI {
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.96 alpha:1].CGColor;

    NSView *sidebar = [[NSView alloc] init];
    sidebar.wantsLayer = YES;
    sidebar.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.08 green:0.10 blue:0.14 alpha:1].CGColor;
    [self.view addSubview:sidebar];
    [sidebar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.equalTo(self.view);
        make.width.mas_equalTo(188);
    }];

    NSTextField *appTitle = [self labelWithString:@"OJO Print" fontSize:22 weight:NSFontWeightSemibold color:[NSColor whiteColor]];
    NSTextField *appSubtitle = [self labelWithString:@"Receipts · Labels" fontSize:12 weight:NSFontWeightRegular color:[NSColor colorWithCalibratedWhite:0.76 alpha:1]];
    [sidebar addSubview:appTitle];
    [sidebar addSubview:appSubtitle];
    [appTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sidebar).offset(22);
        make.left.equalTo(sidebar).offset(18);
        make.right.equalTo(sidebar).offset(-14);
        make.height.mas_equalTo(28);
    }];
    [appSubtitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(appTitle.mas_bottom).offset(2);
        make.left.right.equalTo(appTitle);
        make.height.mas_equalTo(18);
    }];

    NSArray<NSDictionary *> *items = @[
        @{@"title": @"Connect", @"tag": @(SMAppSectionConnect)},
        @{@"title": @"Receipts", @"tag": @(SMAppSectionReceipt)},
        @{@"title": @"Labels", @"tag": @(SMAppSectionLabels)},
        @{@"title": @"Designer", @"tag": @(SMAppSectionDesigner)},
    ];
    NSButton *previousButton = nil;
    for (NSDictionary *item in items) {
        SMAppSection section = [item[@"tag"] integerValue];
        NSButton *button = [self sidebarButtonWithTitle:item[@"title"] section:section];
        self.sidebarButtons[@(section)] = button;
        [sidebar addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(sidebar).offset(14);
            make.right.equalTo(sidebar).offset(-14);
            make.height.mas_equalTo(42);
            if (previousButton) {
                make.top.equalTo(previousButton.mas_bottom).offset(8);
            }
            else {
                make.top.equalTo(appSubtitle.mas_bottom).offset(28);
            }
        }];
        previousButton = button;
    }

    NSTextField *protocolNote = [self labelWithString:@"Receipts use ESC/POS\nLabels use TSPL" fontSize:11 weight:NSFontWeightRegular color:[NSColor colorWithCalibratedWhite:0.68 alpha:1]];
    [sidebar addSubview:protocolNote];
    [protocolNote mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sidebar).offset(18);
        make.right.equalTo(sidebar).offset(-18);
        make.bottom.equalTo(sidebar).offset(-22);
        make.height.mas_equalTo(42);
    }];

    NSView *main = [[NSView alloc] init];
    [self.view addSubview:main];
    [main mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.bottom.equalTo(self.view);
        make.left.equalTo(sidebar.mas_right);
    }];

    NSView *header = [[NSView alloc] init];
    header.wantsLayer = YES;
    header.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.985 alpha:1].CGColor;
    [main addSubview:header];
    [header mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(main);
        make.height.mas_equalTo(88);
    }];

    self.sectionTitleLabel = [self labelWithString:@"Connect" fontSize:25 weight:NSFontWeightSemibold color:COLOR_33];
    self.sectionSubtitleLabel = [self labelWithString:@"Choose a printer connection before printing." fontSize:13 weight:NSFontWeightRegular color:COLOR_77];
    self.statusLabel = [self labelWithString:@"" fontSize:12 weight:NSFontWeightRegular color:COLOR_77];
    [header addSubview:self.sectionTitleLabel];
    [header addSubview:self.sectionSubtitleLabel];
    [header addSubview:self.statusLabel];

    [self.sectionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(header).offset(16);
        make.left.equalTo(header).offset(24);
        make.right.equalTo(header).offset(-260);
        make.height.mas_equalTo(30);
    }];
    [self.sectionSubtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sectionTitleLabel.mas_bottom).offset(2);
        make.left.right.equalTo(self.sectionTitleLabel);
        make.height.mas_equalTo(20);
    }];
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(header);
        make.right.equalTo(header).offset(-24);
        make.width.mas_equalTo(260);
        make.height.mas_equalTo(40);
    }];

    self.contentContainer = [[NSView alloc] init];
    [main addSubview:self.contentContainer];
    [self.contentContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(header.mas_bottom);
        make.left.right.bottom.equalTo(main);
    }];

    self.connectionPage = [self buildConnectionPage];
    self.receiptPage = [self buildReceiptPage];
    self.labelPage = [self buildLabelPage];
    self.designerPage = [self buildDesignerPage];
    NSArray<NSView *> *pages = @[self.connectionPage, self.receiptPage, self.labelPage, self.designerPage];
    for (NSView *page in pages) {
        [self.contentContainer addSubview:page];
        [page mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentContainer);
        }];
    }
}

- (NSButton *)sidebarButtonWithTitle:(NSString *)title section:(SMAppSection)section {
    NSButton *button = [[NSButton alloc] init];
    button.title = title;
    button.tag = section;
    button.target = self;
    button.action = @selector(sidebarButtonClicked:);
    button.bezelStyle = NSBezelStyleRounded;
    button.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    return button;
}

- (void)sidebarButtonClicked:(NSButton *)sender {
    [self showSection:(SMAppSection)sender.tag];
}

- (void)showSection:(SMAppSection)section {
    self.currentSection = section;
    self.connectionPage.hidden = section != SMAppSectionConnect;
    self.receiptPage.hidden = section != SMAppSectionReceipt;
    self.labelPage.hidden = section != SMAppSectionLabels;
    self.designerPage.hidden = section != SMAppSectionDesigner;

    for (NSNumber *key in self.sidebarButtons) {
        NSButton *button = self.sidebarButtons[key];
        BOOL selected = key.integerValue == section;
        button.state = selected ? NSControlStateValueOn : NSControlStateValueOff;
        button.font = [NSFont systemFontOfSize:14 weight:selected ? NSFontWeightSemibold : NSFontWeightRegular];
    }

    switch (section) {
        case SMAppSectionConnect:
            self.sectionTitleLabel.stringValue = @"Connect Printer";
            self.sectionSubtitleLabel.stringValue = @"Use LAN/Ethernet, USB, or Bluetooth. LAN/USB are recommended for reliable image printing.";
            break;
        case SMAppSectionReceipt:
            self.sectionTitleLabel.stringValue = @"Receipt Printing";
            self.sectionSubtitleLabel.stringValue = @"Receipt mode uses ESC/POS through the SUNMI SDK: text, columns, QR, barcode, image/logo, and cut.";
            [self refreshReceiptPreview:nil];
            break;
        case SMAppSectionLabels:
            self.sectionTitleLabel.stringValue = @"Label Printing";
            self.sectionSubtitleLabel.stringValue = @"Label mode uses TSPL for exact label size, gap alignment, barcode, QR, and positioned content.";
            [self refreshLabelPreview:nil];
            break;
        case SMAppSectionDesigner:
            self.sectionTitleLabel.stringValue = @"Label Designer";
            self.sectionSubtitleLabel.stringValue = @"Choose media, place text/images freely, style fonts, then print a WYSIWYG raster label.";
            [self refreshDesignerPreview:nil];
            break;
    }
}

#pragma mark - Pages

- (NSView *)buildConnectionPage {
    NSView *page = [[NSView alloc] init];

    NSBox *card = [self boxWithTitle:@"Printer connection" detail:@"Pick the transport that matches the printer. Ethernet/IP is best for shared receipt stations; USB is best for local reliability."];
    [page addSubview:card];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(page).offset(22);
        make.left.equalTo(page).offset(24);
        make.right.equalTo(page).offset(-24);
        make.height.mas_equalTo(210);
    }];

    self.connectionSummaryLabel = [self labelWithString:@"Not connected" fontSize:14 weight:NSFontWeightMedium color:COLOR_33];
    [card addSubview:self.connectionSummaryLabel];
    [self.connectionSummaryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(50);
        make.left.equalTo(card).offset(16);
        make.right.equalTo(card).offset(-16);
        make.height.mas_equalTo(24);
    }];

    NSButton *usbButton = [self buttonWithTitle:@"Connect USB" action:@selector(connectUSB:)];
    NSButton *lanButton = [self buttonWithTitle:@"Browse LAN" action:@selector(connectIP:)];
    NSButton *bluetoothButton = [self buttonWithTitle:@"Bluetooth" action:@selector(connectBluetooth:)];
    NSButton *wifiButton = [self buttonWithTitle:@"Wi‑Fi Setup" action:@selector(openWiFiSetup:)];
    NSButton *disconnectButton = [self buttonWithTitle:@"Disconnect" action:@selector(disconnectPrinter:)];
    NSArray *buttons = @[usbButton, lanButton, bluetoothButton, wifiButton, disconnectButton];
    NSButton *previous = nil;
    for (NSButton *button in buttons) {
        [card addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.connectionSummaryLabel.mas_bottom).offset(14);
            make.width.mas_equalTo(118);
            make.height.mas_equalTo(34);
            if (previous) {
                make.left.equalTo(previous.mas_right).offset(10);
            }
            else {
                make.left.equalTo(card).offset(16);
            }
        }];
        previous = button;
    }

    NSTextField *ipLabel = [self labelWithString:@"Manual LAN/IP address" fontSize:11 weight:NSFontWeightRegular color:COLOR_77];
    self.manualIPField = [self textFieldWithValue:@"" action:@selector(connectManualIP:)];
    self.manualIPField.placeholderString = @"e.g. 192.168.1.50";
    NSButton *manualIPButton = [self primaryButtonWithTitle:@"Connect IP" action:@selector(connectManualIP:)];
    [card addSubview:ipLabel];
    [card addSubview:self.manualIPField];
    [card addSubview:manualIPButton];
    [ipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(usbButton.mas_bottom).offset(22);
        make.left.equalTo(card).offset(16);
        make.width.mas_equalTo(180);
        make.height.mas_equalTo(18);
    }];
    [self.manualIPField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(ipLabel.mas_bottom).offset(4);
        make.left.equalTo(ipLabel);
        make.width.mas_equalTo(240);
        make.height.mas_equalTo(28);
    }];
    [manualIPButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.manualIPField);
        make.left.equalTo(self.manualIPField.mas_right).offset(10);
        make.width.mas_equalTo(110);
        make.height.mas_equalTo(30);
    }];

    NSBox *workflowCard = [self boxWithTitle:@"Printing workflows" detail:@"The app chooses the strongest command language for the job, then sends raw bytes through the selected connection."];
    [page addSubview:workflowCard];
    [workflowCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card.mas_bottom).offset(18);
        make.left.right.equalTo(card);
        make.height.mas_equalTo(220);
    }];

    NSTextField *receiptInfo = [self labelWithString:@"Receipt mode · ESC/POS/SUNMI SDK\nBest for receipts, logos/images, QR codes, barcodes, cash drawer, cutter, and continuous paper." fontSize:13 weight:NSFontWeightRegular color:COLOR_33];
    NSTextField *labelInfo = [self labelWithString:@"Label mode · TSPL\nBest for labels with exact dimensions, gap/black-mark sensing, positioned text, barcodes, QR codes, and repeatable alignment." fontSize:13 weight:NSFontWeightRegular color:COLOR_33];
    [workflowCard addSubview:receiptInfo];
    [workflowCard addSubview:labelInfo];
    [receiptInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(workflowCard).offset(54);
        make.left.equalTo(workflowCard).offset(18);
        make.right.equalTo(workflowCard).offset(-18);
        make.height.mas_equalTo(58);
    }];
    [labelInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(receiptInfo.mas_bottom).offset(20);
        make.left.right.equalTo(receiptInfo);
        make.height.mas_equalTo(58);
    }];

    return page;
}

- (NSView *)buildReceiptPage {
    NSView *page = [[NSView alloc] init];

    NSBox *settingsBox = [self boxWithTitle:@"Receipt settings" detail:@"Continuous-paper receipt mode."];
    [page addSubview:settingsBox];
    [settingsBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(page).offset(22);
        make.left.equalTo(page).offset(24);
        make.width.mas_equalTo(360);
        make.height.mas_equalTo(152);
    }];

    self.receiptWidthPopup = [[NSPopUpButton alloc] init];
    [self.receiptWidthPopup addItemsWithTitles:@[@"80 mm / 576 dots", @"58 mm / 384 dots"]];
    self.receiptWidthPopup.target = self;
    self.receiptWidthPopup.action = @selector(refreshReceiptPreview:);
    self.receiptDensityField = [self textFieldWithValue:@"110" action:@selector(refreshReceiptPreview:)];
    self.receiptSpeedField = [self textFieldWithValue:@"120" action:@selector(refreshReceiptPreview:)];
    self.receiptLogoButton = [self checkboxWithTitle:@"Print logo/image" action:@selector(refreshReceiptPreview:) checked:YES];
    self.receiptCutButton = [self checkboxWithTitle:@"Cut paper" action:@selector(refreshReceiptPreview:) checked:YES];
    self.receiptCashDrawerButton = [self checkboxWithTitle:@"Open cash drawer" action:@selector(refreshReceiptPreview:) checked:NO];

    [self addLabeledControl:self.receiptWidthPopup title:@"Paper" toView:settingsBox top:48 left:16 width:150 height:28];
    [self addLabeledControl:self.receiptDensityField title:@"Density" toView:settingsBox top:48 left:182 width:70 height:28];
    [self addLabeledControl:self.receiptSpeedField title:@"Speed" toView:settingsBox top:48 left:268 width:70 height:28];
    [settingsBox addSubview:self.receiptLogoButton];
    [settingsBox addSubview:self.receiptCutButton];
    [settingsBox addSubview:self.receiptCashDrawerButton];
    [self.receiptLogoButton mas_makeConstraints:^(MASConstraintMaker *make) { make.top.equalTo(settingsBox).offset(104); make.left.equalTo(settingsBox).offset(16); make.width.mas_equalTo(120); make.height.mas_equalTo(22); }];
    [self.receiptCutButton mas_makeConstraints:^(MASConstraintMaker *make) { make.top.equalTo(self.receiptLogoButton); make.left.equalTo(self.receiptLogoButton.mas_right).offset(16); make.width.mas_equalTo(90); make.height.mas_equalTo(22); }];
    [self.receiptCashDrawerButton mas_makeConstraints:^(MASConstraintMaker *make) { make.top.equalTo(self.receiptLogoButton); make.left.equalTo(self.receiptCutButton.mas_right).offset(16); make.width.mas_equalTo(130); make.height.mas_equalTo(22); }];

    NSBox *contentBox = [self boxWithTitle:@"Receipt content" detail:@"Sample order fields. Item lines are generated by the sample receipt model."];
    [page addSubview:contentBox];
    [contentBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(settingsBox.mas_bottom).offset(14);
        make.left.right.equalTo(settingsBox);
        make.height.mas_equalTo(356);
    }];

    SMReceiptContent *sample = [SMReceiptContent sampleReceipt];
    self.receiptStoreField = [self textFieldWithValue:sample.storeName action:@selector(refreshReceiptPreview:)];
    self.receiptAddressField = [self textFieldWithValue:@"123 Market Street, San Francisco" action:@selector(refreshReceiptPreview:)];
    self.receiptPhoneField = [self textFieldWithValue:sample.storePhone action:@selector(refreshReceiptPreview:)];
    self.receiptOrderField = [self textFieldWithValue:sample.orderNumber action:@selector(refreshReceiptPreview:)];
    self.receiptCashierField = [self textFieldWithValue:sample.cashierName action:@selector(refreshReceiptPreview:)];
    self.receiptFooterField = [self textFieldWithValue:sample.footerText action:@selector(refreshReceiptPreview:)];
    self.receiptBarcodeField = [self textFieldWithValue:sample.barcodeValue action:@selector(refreshReceiptPreview:)];
    self.receiptQRField = [self textFieldWithValue:sample.qrValue action:@selector(refreshReceiptPreview:)];

    [self addLabeledControl:self.receiptStoreField title:@"Store" toView:contentBox top:48 left:16 width:150 height:26];
    [self addLabeledControl:self.receiptPhoneField title:@"Phone" toView:contentBox top:48 left:186 width:150 height:26];
    [self addLabeledControl:self.receiptAddressField title:@"Address" toView:contentBox top:100 left:16 width:320 height:26];
    [self addLabeledControl:self.receiptOrderField title:@"Order no." toView:contentBox top:152 left:16 width:150 height:26];
    [self addLabeledControl:self.receiptCashierField title:@"Cashier" toView:contentBox top:152 left:186 width:150 height:26];
    [self addLabeledControl:self.receiptBarcodeField title:@"Barcode" toView:contentBox top:204 left:16 width:320 height:26];
    [self addLabeledControl:self.receiptQRField title:@"QR / Digital receipt URL" toView:contentBox top:256 left:16 width:320 height:26];
    [self addLabeledControl:self.receiptFooterField title:@"Footer" toView:contentBox top:308 left:16 width:320 height:26];

    NSButton *refreshButton = [self buttonWithTitle:@"Refresh Preview" action:@selector(refreshReceiptPreview:)];
    NSButton *printButton = [self primaryButtonWithTitle:@"Print Receipt" action:@selector(printReceipt:)];
    [page addSubview:refreshButton];
    [page addSubview:printButton];
    [refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentBox.mas_bottom).offset(14);
        make.left.equalTo(contentBox);
        make.width.mas_equalTo(140);
        make.height.mas_equalTo(36);
    }];
    [printButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(refreshButton);
        make.left.equalTo(refreshButton.mas_right).offset(12);
        make.width.mas_equalTo(140);
        make.height.mas_equalTo(36);
    }];

    NSBox *previewBox = [self boxWithTitle:@"Receipt preview" detail:@"Visual receipt preview at printer-dot width. The logo/image is capped to this same printable area."];
    [page addSubview:previewBox];
    [previewBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(settingsBox);
        make.left.equalTo(settingsBox.mas_right).offset(18);
        make.right.equalTo(page).offset(-24);
        make.bottom.equalTo(page).offset(-22);
    }];
    self.receiptPreviewImageView = [self imageViewInBox:previewBox];

    return page;
}

- (NSView *)buildLabelPage {
    NSView *page = [[NSView alloc] init];

    NSBox *settingsBox = [self boxWithTitle:@"Label media" detail:@"For label-mode printers. Calibrate once after loading media; normal print does not HOME/feed an extra label."];
    [page addSubview:settingsBox];
    [settingsBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(page).offset(22);
        make.left.equalTo(page).offset(24);
        make.right.equalTo(page).offset(-24);
        make.height.mas_equalTo(120);
    }];

    self.widthField = [self textFieldWithValue:@"50" action:@selector(refreshLabelPreview:)];
    self.heightField = [self textFieldWithValue:@"20" action:@selector(refreshLabelPreview:)];
    self.gapField = [self textFieldWithValue:@"3" action:@selector(refreshLabelPreview:)];
    self.speedField = [self textFieldWithValue:@"3" action:@selector(refreshLabelPreview:)];
    self.densityField = [self textFieldWithValue:@"12" action:@selector(refreshLabelPreview:)];
    [self addLabeledControl:self.widthField title:@"Width mm" toView:settingsBox top:54 left:16 width:82 height:26];
    [self addLabeledControl:self.heightField title:@"Height mm" toView:settingsBox top:54 left:114 width:82 height:26];
    [self addLabeledControl:self.gapField title:@"Gap mm" toView:settingsBox top:54 left:212 width:82 height:26];
    [self addLabeledControl:self.speedField title:@"Speed" toView:settingsBox top:54 left:310 width:82 height:26];
    [self addLabeledControl:self.densityField title:@"Density" toView:settingsBox top:54 left:408 width:82 height:26];

    NSBox *contentBox = [self boxWithTitle:@"Label content" detail:@"Product label sample. For receipt-mode printers, switch the device back to label mode before printing TSPL labels."];
    [page addSubview:contentBox];
    [contentBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(settingsBox.mas_bottom).offset(14);
        make.left.right.equalTo(settingsBox);
        make.height.mas_equalTo(158);
    }];

    SMLabelContent *sample = [SMLabelContent sampleContent];
    self.brandField = [self textFieldWithValue:sample.brand action:@selector(refreshLabelPreview:)];
    self.productField = [self textFieldWithValue:sample.productName action:@selector(refreshLabelPreview:)];
    self.skuField = [self textFieldWithValue:sample.sku action:@selector(refreshLabelPreview:)];
    self.priceField = [self textFieldWithValue:sample.price action:@selector(refreshLabelPreview:)];
    self.qrField = [self textFieldWithValue:sample.qrValue action:@selector(refreshLabelPreview:)];
    [self addLabeledControl:self.brandField title:@"Brand" toView:contentBox top:54 left:16 width:150 height:26];
    [self addLabeledControl:self.productField title:@"Product" toView:contentBox top:54 left:182 width:320 height:26];
    [self addLabeledControl:self.priceField title:@"Price" toView:contentBox top:54 left:520 width:110 height:26];
    [self addLabeledControl:self.skuField title:@"Barcode / SKU" toView:contentBox top:106 left:16 width:220 height:26];
    [self addLabeledControl:self.qrField title:@"QR value" toView:contentBox top:106 left:252 width:378 height:26];

    NSView *actionRow = [[NSView alloc] init];
    [page addSubview:actionRow];
    [actionRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentBox.mas_bottom).offset(14);
        make.left.right.equalTo(contentBox);
        make.height.mas_equalTo(38);
    }];
    NSButton *calibrateButton = [self buttonWithTitle:@"Calibrate / Align Sensor" action:@selector(calibrateSensor:)];
    NSButton *refreshButton = [self buttonWithTitle:@"Refresh Preview" action:@selector(refreshLabelPreview:)];
    NSButton *printButton = [self primaryButtonWithTitle:@"Print Label" action:@selector(printLabel:)];
    [actionRow addSubview:calibrateButton];
    [actionRow addSubview:refreshButton];
    [actionRow addSubview:printButton];
    [calibrateButton mas_makeConstraints:^(MASConstraintMaker *make) { make.left.top.bottom.equalTo(actionRow); make.width.mas_equalTo(180); }];
    [refreshButton mas_makeConstraints:^(MASConstraintMaker *make) { make.left.equalTo(calibrateButton.mas_right).offset(10); make.top.bottom.equalTo(actionRow); make.width.mas_equalTo(140); }];
    [printButton mas_makeConstraints:^(MASConstraintMaker *make) { make.right.top.bottom.equalTo(actionRow); make.width.mas_equalTo(140); }];

    NSBox *previewBox = [self boxWithTitle:@"Generated TSPL" detail:@"Raw label commands sent to the printer."];
    [page addSubview:previewBox];
    [previewBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(actionRow.mas_bottom).offset(14);
        make.left.right.equalTo(actionRow);
        make.bottom.equalTo(page).offset(-22);
    }];
    self.labelPreviewTextView = [self textViewInBox:previewBox editable:NO];

    return page;
}

- (NSView *)buildDesignerPage {
    NSView *page = [[NSView alloc] init];

    NSBox *mediaBox = [self boxWithTitle:@"Label setup" detail:@"Choose the physical media first. The canvas is dot-accurate at 203 DPI."];
    [page addSubview:mediaBox];
    [mediaBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(page).offset(22);
        make.left.equalTo(page).offset(24);
        make.width.mas_equalTo(286);
        make.height.mas_equalTo(176);
    }];

    self.designerPresetPopup = [[NSPopUpButton alloc] init];
    [self.designerPresetPopup addItemsWithTitles:@[@"50 × 20 mm", @"78 × 60 mm", @"Custom"]];
    self.designerPresetPopup.target = self;
    self.designerPresetPopup.action = @selector(designerPresetChanged:);
    self.designerWidthField = [self textFieldWithValue:@"50" action:@selector(designerMediaChanged:)];
    self.designerHeightField = [self textFieldWithValue:@"20" action:@selector(designerMediaChanged:)];
    self.designerGapField = [self textFieldWithValue:@"3" action:@selector(refreshDesignerPreview:)];
    self.designerDensityField = [self textFieldWithValue:@"12" action:@selector(refreshDesignerPreview:)];
    [self addLabeledControl:self.designerPresetPopup title:@"Preset" toView:mediaBox top:54 left:16 width:252 height:26];
    [self addLabeledControl:self.designerWidthField title:@"Width" toView:mediaBox top:106 left:16 width:58 height:24];
    [self addLabeledControl:self.designerHeightField title:@"Height" toView:mediaBox top:106 left:84 width:58 height:24];
    [self addLabeledControl:self.designerGapField title:@"Gap" toView:mediaBox top:106 left:152 width:50 height:24];
    [self addLabeledControl:self.designerDensityField title:@"Density" toView:mediaBox top:106 left:212 width:56 height:24];

    NSBox *toolsBox = [self boxWithTitle:@"Tools" detail:@"Add elements, select them on the canvas, then drag to place."];
    [page addSubview:toolsBox];
    [toolsBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(mediaBox.mas_bottom).offset(12);
        make.left.right.equalTo(mediaBox);
        make.height.mas_equalTo(132);
    }];
    NSButton *addTextButton = [self buttonWithTitle:@"Add Text" action:@selector(addDesignerText:)];
    NSButton *addImageButton = [self buttonWithTitle:@"Add Image…" action:@selector(addDesignerImage:)];
    NSButton *duplicateButton = [self buttonWithTitle:@"Duplicate" action:@selector(duplicateDesignerElement:)];
    NSButton *deleteButton = [self buttonWithTitle:@"Delete" action:@selector(deleteDesignerElement:)];
    self.designerGridButton = [self checkboxWithTitle:@"Grid" action:@selector(toggleDesignerGrid:) checked:YES];
    NSArray *toolButtons = @[addTextButton, addImageButton, duplicateButton, deleteButton];
    for (NSInteger i = 0; i < toolButtons.count; i++) {
        NSButton *button = toolButtons[i];
        [toolsBox addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(toolsBox).offset(54 + (i / 2) * 36);
            make.left.equalTo(toolsBox).offset(16 + (i % 2) * 132);
            make.width.mas_equalTo(120);
            make.height.mas_equalTo(28);
        }];
    }
    [toolsBox addSubview:self.designerGridButton];
    [self.designerGridButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(toolsBox).offset(16);
        make.bottom.equalTo(toolsBox).offset(-8);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(22);
    }];

    NSBox *inspectorBox = [self boxWithTitle:@"Inspector" detail:@"Position is in printer dots. Text is printed as raster, so macOS fonts are preserved."];
    [page addSubview:inspectorBox];
    [inspectorBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(toolsBox.mas_bottom).offset(12);
        make.left.right.equalTo(mediaBox);
        make.bottom.equalTo(page).offset(-82);
    }];
    self.designerElementTextField = [self textFieldWithValue:@"" action:@selector(designerInspectorChanged:)];
    self.designerXField = [self textFieldWithValue:@"" action:@selector(designerInspectorChanged:)];
    self.designerYField = [self textFieldWithValue:@"" action:@selector(designerInspectorChanged:)];
    self.designerWField = [self textFieldWithValue:@"" action:@selector(designerInspectorChanged:)];
    self.designerHField = [self textFieldWithValue:@"" action:@selector(designerInspectorChanged:)];
    self.designerFontPopup = [[NSPopUpButton alloc] init];
    [self.designerFontPopup addItemsWithTitles:@[@"Helvetica Neue", @"Menlo", @"Arial", @"Avenir Next", @"Times New Roman"]];
    self.designerFontPopup.target = self;
    self.designerFontPopup.action = @selector(designerInspectorChanged:);
    self.designerFontSizeField = [self textFieldWithValue:@"24" action:@selector(designerInspectorChanged:)];
    self.designerBoldButton = [self checkboxWithTitle:@"Bold" action:@selector(designerInspectorChanged:) checked:NO];
    self.designerAlignPopup = [[NSPopUpButton alloc] init];
    [self.designerAlignPopup addItemsWithTitles:@[@"Left", @"Center", @"Right"]];
    self.designerAlignPopup.target = self;
    self.designerAlignPopup.action = @selector(designerInspectorChanged:);

    [self addLabeledControl:self.designerElementTextField title:@"Text" toView:inspectorBox top:46 left:16 width:252 height:24];
    [self addLabeledControl:self.designerXField title:@"X" toView:inspectorBox top:92 left:16 width:52 height:24];
    [self addLabeledControl:self.designerYField title:@"Y" toView:inspectorBox top:92 left:82 width:52 height:24];
    [self addLabeledControl:self.designerWField title:@"W" toView:inspectorBox top:92 left:148 width:52 height:24];
    [self addLabeledControl:self.designerHField title:@"H" toView:inspectorBox top:92 left:214 width:52 height:24];
    [self addLabeledControl:self.designerFontPopup title:@"Font" toView:inspectorBox top:136 left:16 width:150 height:26];
    [self addLabeledControl:self.designerFontSizeField title:@"Size" toView:inspectorBox top:136 left:182 width:52 height:24];
    [inspectorBox addSubview:self.designerBoldButton];
    [inspectorBox addSubview:self.designerAlignPopup];
    [self.designerBoldButton mas_makeConstraints:^(MASConstraintMaker *make) { make.top.equalTo(inspectorBox).offset(174); make.left.equalTo(inspectorBox).offset(16); make.width.mas_equalTo(70); make.height.mas_equalTo(22); }];
    [self.designerAlignPopup mas_makeConstraints:^(MASConstraintMaker *make) { make.top.equalTo(inspectorBox).offset(170); make.left.equalTo(inspectorBox).offset(104); make.width.mas_equalTo(112); make.height.mas_equalTo(26); }];

    self.designerPreviewTextView = [[NSTextView alloc] init];

    NSButton *calibrateButton = [self buttonWithTitle:@"Calibrate" action:@selector(calibrateDesignedLabel:)];
    NSButton *printButton = [self primaryButtonWithTitle:@"Print Label" action:@selector(printDesignedLabel:)];
    [page addSubview:calibrateButton];
    [page addSubview:printButton];
    [calibrateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(mediaBox);
        make.bottom.equalTo(page).offset(-24);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(38);
    }];
    [printButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(calibrateButton.mas_right).offset(12);
        make.bottom.equalTo(calibrateButton);
        make.width.mas_equalTo(132);
        make.height.mas_equalTo(38);
    }];

    NSBox *canvasBox = [self boxWithTitle:@"Canvas" detail:@"WYSIWYG raster label. Drag elements freely; imported images and chosen fonts print as shown."];
    [page addSubview:canvasBox];
    [canvasBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(page).offset(22);
        make.left.equalTo(mediaBox.mas_right).offset(18);
        make.right.equalTo(page).offset(-24);
        make.bottom.equalTo(page).offset(-22);
    }];
    NSScrollView *canvasScroll = [[NSScrollView alloc] init];
    canvasScroll.hasHorizontalScroller = YES;
    canvasScroll.hasVerticalScroller = YES;
    canvasScroll.borderType = NSBezelBorder;
    self.designerCanvasView = [[SMLabelDesignerCanvasView alloc] initWithFrame:NSMakeRect(0, 0, 560, 380)];
    self.designerCanvasView.delegate = self;
    canvasScroll.documentView = self.designerCanvasView;
    [canvasBox addSubview:canvasScroll];
    [canvasScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(canvasBox).offset(52);
        make.left.equalTo(canvasBox).offset(14);
        make.right.equalTo(canvasBox).offset(-14);
        make.bottom.equalTo(canvasBox).offset(-14);
    }];

    [self.designerCanvasView addTextElement];
    [self designerMediaChanged:nil];
    [self updateDesignerInspectorFromSelection];

    return page;
}

#pragma mark - Connection actions

- (void)setupConnectionCallbacks {
    __weak typeof(self) weakSelf = self;
    [[SunmiPrinterManager shareInstance] deviceDisConnectWithBlock:^(CBPeripheral *device, NSError *err) {
        __strong typeof(weakSelf) self = weakSelf;
        if ([self.connection.blePrinterModel.peripheral isEqual:device]) {
            [self.connection disconnect];
            [self updateConnectionStatus:@"Bluetooth printer disconnected."];
        }
    }];

    [[SunmiPrinterIPManager sharedManager] deviceDisConnectWithBlock:^(NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self.connection.type == PrintConnectIP) {
            [self.connection disconnect];
            [self updateConnectionStatus:@"LAN/IP printer disconnected."];
        }
    }];
}

- (void)connectBluetooth:(id)sender {
    __weak typeof(self) weakSelf = self;
    DeviceListViewController *listVc = [[DeviceListViewController alloc] init];
    listVc.printType = PrintConnectBluetooth;
    listVc.connectedStatusBlock = ^(SunmiBlePrinterModel * _Nonnull model, PrintConnectType printConnectType) {
        __strong typeof(weakSelf) self = weakSelf;
        [self.connection setBluetoothPrinter:model];
        [self updateConnectionStatus:[NSString stringWithFormat:@"Connected over Bluetooth: %@", self.connection.displayName]];
        [self showSection:SMAppSectionReceipt];
    };
    [self presentViewControllerAsModalWindow:listVc];
}

- (void)connectIP:(id)sender {
    __weak typeof(self) weakSelf = self;
    DeviceListViewController *listVc = [[DeviceListViewController alloc] init];
    listVc.printType = PrintConnectIP;
    listVc.connectedIPStatusBlock = ^(SunmiIpPrinterModel * _Nonnull model, PrintConnectType printConnectType) {
        __strong typeof(weakSelf) self = weakSelf;
        [self.connection setIPPrinter:model];
        [self updateConnectionStatus:[NSString stringWithFormat:@"Connected over LAN: %@", self.connection.displayName]];
        [self showSection:SMAppSectionReceipt];
    };
    [self presentViewControllerAsModalWindow:listVc];
}

- (void)connectManualIP:(id)sender {
    [self updateConnectionStatus:@"Connecting to LAN printer…"];
    __weak typeof(self) weakSelf = self;
    [self.connection connectIPWithAddress:self.manualIPField.stringValue completion:^(NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (error) {
            [self updateConnectionStatus:@"LAN connection failed."];
            [self alertMsg:error.localizedDescription ?: @"Could not connect to the printer IP address." title:@"LAN Connection Failed"];
        }
        else {
            [self updateConnectionStatus:[NSString stringWithFormat:@"Connected over LAN: %@", self.connection.displayName]];
            [self showSection:SMAppSectionReceipt];
        }
    }];
}

- (void)connectUSB:(id)sender {
    NSError *error = nil;
    if ([self.connection connectUSB:&error]) {
        [self updateConnectionStatus:[NSString stringWithFormat:@"Connected over USB: %@", self.connection.displayName]];
        [self showSection:SMAppSectionReceipt];
    }
    else {
        [self updateConnectionStatus:@"USB printer not found."];
        [self alertMsg:error.localizedDescription ?: @"No SUNMI USB printer found." title:@"USB Printer Not Found"];
    }
}

- (void)disconnectPrinter:(id)sender {
    [self.connection disconnect];
    [self updateConnectionStatus:@"Printer disconnected."];
    [self showSection:SMAppSectionConnect];
}

- (void)openWiFiSetup:(id)sender {
    if (enterNetworkModeCommand) {
        PrinterSearchingController *searchViewController = [[PrinterSearchingController alloc] init];
        [self presentViewControllerAsModalWindow:searchViewController];
    }
    else {
        PrinterSettingEntranceController *vc = [[PrinterSettingEntranceController alloc] init];
        [self presentViewControllerAsModalWindow:vc];
    }
}

- (BOOL)ensureConnection {
    if (self.connection.isConnected) {
        return YES;
    }

    NSError *error = nil;
    if ([self.connection connectUSB:&error]) {
        [self updateConnectionStatus:[NSString stringWithFormat:@"Connected over USB: %@", self.connection.displayName]];
        return YES;
    }

    [self updateConnectionStatus:@"No printer connected."];
    [self alertMsg:error.localizedDescription ?: @"Connect via LAN, USB, or Bluetooth first." title:@"Printer Not Connected"];
    [self showSection:SMAppSectionConnect];
    return NO;
}

- (void)updateConnectionStatus:(NSString *)message {
    NSString *status = message ?: @"";
    self.statusLabel.stringValue = status;
    if (self.connectionSummaryLabel) {
        if (self.connection.isConnected) {
            self.connectionSummaryLabel.stringValue = [NSString stringWithFormat:@"Ready: %@", self.connection.displayName];
        }
        else {
            self.connectionSummaryLabel.stringValue = status.length ? status : @"Not connected";
        }
    }
}

#pragma mark - Receipt actions

- (void)refreshReceiptPreview:(id)sender {
    SMReceiptPrintSettings *settings = [self receiptSettingsFromUI];
    SMReceiptContent *content = [self receiptContentFromUI];
    NSImage *preview = [SMReceiptCommandBuilder previewImageForReceiptWithSettings:settings content:content];
    self.receiptPreviewImageView.image = preview;
    self.receiptPreviewImageView.frame = NSMakeRect(0, 0, preview.size.width, preview.size.height);
}

- (void)printReceipt:(id)sender {
    if (![self ensureConnection]) {
        return;
    }
    [self refreshReceiptPreview:nil];
    NSData *data = [SMReceiptCommandBuilder dataForReceiptWithSettings:[self receiptSettingsFromUI] content:[self receiptContentFromUI]];
    [self sendPrintData:data successMessage:@"Receipt sent to printer." failureTitle:@"Receipt Print Failed"];
}

- (SMReceiptPrintSettings *)receiptSettingsFromUI {
    BOOL is58 = self.receiptWidthPopup.indexOfSelectedItem == 1;
    SMReceiptPrintSettings *settings = is58 ? [SMReceiptPrintSettings default58mmSettings] : [SMReceiptPrintSettings default80mmSettings];
    settings.density = [self integerFromField:self.receiptDensityField fallback:110 min:70 max:130];
    settings.speed = [self integerFromField:self.receiptSpeedField fallback:is58 ? 100 : 120 min:0 max:250];
    settings.includeLogo = self.receiptLogoButton.state == NSControlStateValueOn;
    settings.cutPaper = self.receiptCutButton.state == NSControlStateValueOn;
    settings.openCashDrawer = self.receiptCashDrawerButton.state == NSControlStateValueOn;
    return settings;
}

- (SMReceiptContent *)receiptContentFromUI {
    SMReceiptContent *content = [SMReceiptContent sampleReceipt];
    content.storeName = self.receiptStoreField.stringValue.length ? self.receiptStoreField.stringValue : @"Store";
    content.storeAddress = self.receiptAddressField.stringValue.length ? self.receiptAddressField.stringValue : @"";
    content.storePhone = self.receiptPhoneField.stringValue.length ? self.receiptPhoneField.stringValue : @"";
    content.orderNumber = self.receiptOrderField.stringValue.length ? self.receiptOrderField.stringValue : @"-";
    content.cashierName = self.receiptCashierField.stringValue.length ? self.receiptCashierField.stringValue : @"-";
    content.footerText = self.receiptFooterField.stringValue.length ? self.receiptFooterField.stringValue : @"";
    content.barcodeValue = self.receiptBarcodeField.stringValue;
    content.qrValue = self.receiptQRField.stringValue;
    return content;
}

#pragma mark - Label actions

- (void)refreshLabelPreview:(id)sender {
    SMLabelPrintSettings *settings = [self labelSettingsFromUI];
    SMLabelContent *content = [self labelContentFromUI];
    NSString *tspl = [SMLabelCommandBuilder TSPLForSampleLabelWithSettings:settings content:content];
    self.labelPreviewTextView.string = tspl ?: @"";
}

- (void)calibrateSensor:(id)sender {
    if (![self ensureConnection]) {
        return;
    }
    NSData *data = [SMLabelCommandBuilder dataForGapCalibrationWithSettings:[self labelSettingsFromUI]];
    [self sendPrintData:data successMessage:@"Label sensor calibration sent." failureTitle:@"Calibration Failed"];
}

- (void)printLabel:(id)sender {
    if (![self ensureConnection]) {
        return;
    }
    [self refreshLabelPreview:nil];
    NSString *tspl = self.labelPreviewTextView.string;
    NSData *data = [tspl dataUsingEncoding:NSUTF8StringEncoding];
    [self sendPrintData:data successMessage:@"Label sent to printer." failureTitle:@"Label Print Failed"];
}

- (SMLabelPrintSettings *)labelSettingsFromUI {
    SMLabelPrintSettings *settings = [SMLabelPrintSettings default50x20Settings];
    settings.widthMM = [self doubleFromField:self.widthField fallback:50 min:10 max:120];
    settings.heightMM = [self doubleFromField:self.heightField fallback:20 min:8 max:200];
    settings.gapMM = [self doubleFromField:self.gapField fallback:3 min:0 max:20];
    settings.speed = [self integerFromField:self.speedField fallback:3 min:2 max:8];
    settings.density = [self integerFromField:self.densityField fallback:12 min:0 max:15];
    settings.direction = 1;
    settings.copies = 1;
    settings.alignToGapBeforePrint = NO;
    return settings;
}

- (SMLabelContent *)labelContentFromUI {
    SMLabelContent *content = [[SMLabelContent alloc] init];
    content.brand = self.brandField.stringValue.length ? self.brandField.stringValue : @"OJO";
    content.productName = self.productField.stringValue.length ? self.productField.stringValue : @"Sample Item";
    content.sku = self.skuField.stringValue.length ? self.skuField.stringValue : @"SKU001234";
    content.price = self.priceField.stringValue.length ? self.priceField.stringValue : @"$9.99";
    content.qrValue = self.qrField.stringValue.length ? self.qrField.stringValue : content.sku;
    return content;
}

#pragma mark - Designer actions

- (void)designerPresetChanged:(id)sender {
    NSInteger index = self.designerPresetPopup.indexOfSelectedItem;
    if (index == 0) {
        self.designerWidthField.stringValue = @"50";
        self.designerHeightField.stringValue = @"20";
        self.designerGapField.stringValue = @"3";
    }
    else if (index == 1) {
        self.designerWidthField.stringValue = @"78";
        self.designerHeightField.stringValue = @"60";
        self.designerGapField.stringValue = @"3";
    }
    [self designerMediaChanged:nil];
}

- (void)designerMediaChanged:(id)sender {
    CGFloat width = [self doubleFromField:self.designerWidthField fallback:50 min:10 max:120];
    CGFloat height = [self doubleFromField:self.designerHeightField fallback:20 min:8 max:200];
    [self.designerCanvasView setLabelWidthMM:width heightMM:height];
    [self refreshDesignerPreview:nil];
}

- (void)addDesignerText:(id)sender {
    [self.designerCanvasView addTextElement];
    [self updateDesignerInspectorFromSelection];
    [self refreshDesignerPreview:nil];
}

- (void)addDesignerImage:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"png", @"jpg", @"jpeg", @"gif", @"tiff", @"bmp", @"webp"];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *url = panel.URL;
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
            if (image) {
                [self.designerCanvasView addImageElementWithImage:image path:url.path];
                [self updateDesignerInspectorFromSelection];
                [self refreshDesignerPreview:nil];
            }
        }
    }];
}

- (void)duplicateDesignerElement:(id)sender {
    [self.designerCanvasView duplicateSelectedElement];
    [self updateDesignerInspectorFromSelection];
    [self refreshDesignerPreview:nil];
}

- (void)deleteDesignerElement:(id)sender {
    [self.designerCanvasView deleteSelectedElement];
    [self updateDesignerInspectorFromSelection];
    [self refreshDesignerPreview:nil];
}

- (void)toggleDesignerGrid:(id)sender {
    self.designerCanvasView.showGrid = self.designerGridButton.state == NSControlStateValueOn;
    [self.designerCanvasView setNeedsDisplay:YES];
}

- (void)designerInspectorChanged:(id)sender {
    SMDesignerElement *element = self.designerCanvasView.selectedElement;
    if (!element) {
        return;
    }

    CGRect frame = element.frameDots;
    frame.origin.x = [self doubleFromField:self.designerXField fallback:frame.origin.x min:0 max:self.designerCanvasView.labelWidthDots];
    frame.origin.y = [self doubleFromField:self.designerYField fallback:frame.origin.y min:0 max:self.designerCanvasView.labelHeightDots];
    frame.size.width = [self doubleFromField:self.designerWField fallback:frame.size.width min:4 max:self.designerCanvasView.labelWidthDots];
    frame.size.height = [self doubleFromField:self.designerHField fallback:frame.size.height min:4 max:self.designerCanvasView.labelHeightDots];
    element.frameDots = frame;

    if (element.type == SMDesignerElementTypeText) {
        element.text = self.designerElementTextField.stringValue.length ? self.designerElementTextField.stringValue : @"Text";
        element.fontName = self.designerFontPopup.titleOfSelectedItem ?: @"Helvetica Neue";
        element.fontSizeDots = [self doubleFromField:self.designerFontSizeField fallback:24 min:5 max:140];
        element.bold = self.designerBoldButton.state == NSControlStateValueOn;
        NSInteger alignIndex = self.designerAlignPopup.indexOfSelectedItem;
        element.alignment = alignIndex == 1 ? NSTextAlignmentCenter : (alignIndex == 2 ? NSTextAlignmentRight : NSTextAlignmentLeft);
    }

    [self.designerCanvasView notifyElementChanged];
    [self updateDesignerInspectorFromSelection];
    [self refreshDesignerPreview:nil];
}

- (void)refreshDesignerPreview:(id)sender {
    self.designerPreviewTextView.string = [SMLabelRasterCommandBuilder summaryForDesignedLabelWithSettings:[self designerSettingsFromUI]
                                                                                                  elements:self.designerCanvasView.elements] ?: @"";
}

- (void)calibrateDesignedLabel:(id)sender {
    if (![self ensureConnection]) {
        return;
    }
    NSData *data = [SMLabelCommandBuilder dataForGapCalibrationWithSettings:[self designerSettingsFromUI]];
    [self sendPrintData:data successMessage:@"Label sensor calibration sent." failureTitle:@"Calibration Failed"];
}

- (void)printDesignedLabel:(id)sender {
    if (![self ensureConnection]) {
        return;
    }
    NSData *data = [SMLabelRasterCommandBuilder dataForDesignedLabelWithSettings:[self designerSettingsFromUI]
                                                                       elements:self.designerCanvasView.elements];
    [self sendPrintData:data successMessage:@"Designed label sent to printer." failureTitle:@"Designed Label Print Failed"];
}

- (void)designerCanvasSelectionDidChange:(SMLabelDesignerCanvasView *)canvas {
    [self updateDesignerInspectorFromSelection];
}

- (void)designerCanvasDidChange:(SMLabelDesignerCanvasView *)canvas {
    [self updateDesignerInspectorFromSelection];
    [self refreshDesignerPreview:nil];
}

- (void)updateDesignerInspectorFromSelection {
    SMDesignerElement *element = self.designerCanvasView.selectedElement;
    BOOL hasSelection = element != nil;
    NSArray<NSControl *> *controls = @[
        self.designerElementTextField,
        self.designerXField,
        self.designerYField,
        self.designerWField,
        self.designerHField,
        self.designerFontPopup,
        self.designerFontSizeField,
        self.designerBoldButton,
        self.designerAlignPopup,
    ];
    for (NSControl *control in controls) {
        control.enabled = hasSelection;
    }

    if (!element) {
        self.designerElementTextField.stringValue = @"";
        self.designerXField.stringValue = @"";
        self.designerYField.stringValue = @"";
        self.designerWField.stringValue = @"";
        self.designerHField.stringValue = @"";
        return;
    }

    CGRect frame = element.frameDots;
    self.designerXField.stringValue = [NSString stringWithFormat:@"%.0f", frame.origin.x];
    self.designerYField.stringValue = [NSString stringWithFormat:@"%.0f", frame.origin.y];
    self.designerWField.stringValue = [NSString stringWithFormat:@"%.0f", frame.size.width];
    self.designerHField.stringValue = [NSString stringWithFormat:@"%.0f", frame.size.height];

    BOOL isText = element.type == SMDesignerElementTypeText;
    self.designerElementTextField.enabled = isText;
    self.designerFontPopup.enabled = isText;
    self.designerFontSizeField.enabled = isText;
    self.designerBoldButton.enabled = isText;
    self.designerAlignPopup.enabled = isText;
    self.designerElementTextField.stringValue = isText ? (element.text ?: @"") : @"Image element";
    if (isText) {
        [self.designerFontPopup selectItemWithTitle:element.fontName ?: @"Helvetica Neue"];
        self.designerFontSizeField.stringValue = [NSString stringWithFormat:@"%.0f", element.fontSizeDots];
        self.designerBoldButton.state = element.bold ? NSControlStateValueOn : NSControlStateValueOff;
        NSInteger alignIndex = element.alignment == NSTextAlignmentCenter ? 1 : (element.alignment == NSTextAlignmentRight ? 2 : 0);
        [self.designerAlignPopup selectItemAtIndex:alignIndex];
    }
}

- (SMLabelPrintSettings *)designerSettingsFromUI {
    SMLabelPrintSettings *settings = [SMLabelPrintSettings default50x20Settings];
    settings.widthMM = [self doubleFromField:self.designerWidthField fallback:50 min:10 max:120];
    settings.heightMM = [self doubleFromField:self.designerHeightField fallback:20 min:8 max:200];
    settings.gapMM = [self doubleFromField:self.designerGapField fallback:3 min:0 max:20];
    settings.speed = 3;
    settings.density = [self integerFromField:self.designerDensityField fallback:12 min:0 max:15];
    settings.direction = 1;
    settings.copies = 1;
    settings.alignToGapBeforePrint = NO;
    return settings;
}

#pragma mark - Printing

- (void)sendPrintData:(NSData *)data successMessage:(NSString *)successMessage failureTitle:(NSString *)failureTitle {
    if (data.length == 0) {
        [self alertMsg:@"No command data was generated for this print job." title:@"No Print Data"];
        return;
    }
    [self.connection sendData:data completion:^(NSError * _Nullable error) {
        if (error) {
            [self alertMsg:error.localizedDescription title:failureTitle ?: @"Print Failed"];
        }
        else {
            [self updateConnectionStatus:[NSString stringWithFormat:@"%@ %@", successMessage ?: @"Print job sent.", self.connection.displayName]];
        }
    }];
}

#pragma mark - UI helpers

- (NSButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    NSButton *button = [[NSButton alloc] init];
    button.title = title;
    button.target = self;
    button.action = action;
    button.bezelStyle = NSBezelStyleRounded;
    return button;
}

- (NSButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    NSButton *button = [self buttonWithTitle:title action:action];
    button.keyEquivalent = @"\r";
    return button;
}

- (NSButton *)checkboxWithTitle:(NSString *)title action:(SEL)action checked:(BOOL)checked {
    NSButton *button = [[NSButton alloc] init];
    button.title = title;
    [button setButtonType:NSSwitchButton];
    button.state = checked ? NSControlStateValueOn : NSControlStateValueOff;
    button.target = self;
    button.action = action;
    return button;
}

- (NSTextField *)labelWithString:(NSString *)string fontSize:(CGFloat)fontSize weight:(NSFontWeight)weight color:(NSColor *)color {
    NSTextField *label = [NSTextField labelWithString:string ?: @""];
    label.font = [NSFont systemFontOfSize:fontSize weight:weight];
    label.textColor = color;
    label.maximumNumberOfLines = 3;
    return label;
}

- (NSTextField *)textFieldWithValue:(NSString *)value action:(SEL)action {
    NSTextField *field = [[NSTextField alloc] init];
    field.stringValue = value ?: @"";
    field.target = self;
    field.action = action;
    return field;
}

- (NSBox *)boxWithTitle:(NSString *)title detail:(NSString *)detail {
    NSBox *box = [[NSBox alloc] init];
    box.title = title;
    box.titlePosition = NSAtTop;
    box.boxType = NSBoxPrimary;
    if (detail.length) {
        NSTextField *detailLabel = [self labelWithString:detail fontSize:11 weight:NSFontWeightRegular color:COLOR_77];
        [box addSubview:detailLabel];
        [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(box).offset(18);
            make.left.equalTo(box).offset(14);
            make.right.equalTo(box).offset(-14);
            make.height.mas_equalTo(28);
        }];
    }
    return box;
}

- (void)addLabeledControl:(NSView *)control title:(NSString *)title toView:(NSView *)parent top:(CGFloat)top left:(CGFloat)left width:(CGFloat)width height:(CGFloat)height {
    NSTextField *label = [self labelWithString:title fontSize:11 weight:NSFontWeightRegular color:COLOR_77];
    [parent addSubview:label];
    [parent addSubview:control];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(parent).offset(top);
        make.left.equalTo(parent).offset(left);
        make.width.mas_equalTo(width);
        make.height.mas_equalTo(16);
    }];
    [control mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(label.mas_bottom).offset(3);
        make.left.equalTo(label);
        make.width.mas_equalTo(width);
        make.height.mas_equalTo(height);
    }];
}

- (NSImageView *)imageViewInBox:(NSBox *)box {
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = YES;
    scrollView.borderType = NSBezelBorder;
    scrollView.backgroundColor = [NSColor colorWithCalibratedWhite:0.82 alpha:1];

    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 576, 700)];
    imageView.imageScaling = NSImageScaleNone;
    imageView.imageAlignment = NSImageAlignTopLeft;
    imageView.wantsLayer = YES;
    imageView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    scrollView.documentView = imageView;

    [box addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(box).offset(52);
        make.left.equalTo(box).offset(14);
        make.right.equalTo(box).offset(-14);
        make.bottom.equalTo(box).offset(-14);
    }];
    return imageView;
}

- (NSTextView *)textViewInBox:(NSBox *)box editable:(BOOL)editable {
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = YES;
    scrollView.borderType = NSBezelBorder;
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 520, 420)];
    textView.editable = editable;
    textView.selectable = YES;
    textView.verticallyResizable = YES;
    textView.horizontallyResizable = YES;
    textView.autoresizingMask = NSViewWidthSizable;
    textView.minSize = NSMakeSize(0, 0);
    textView.maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    textView.font = [NSFont fontWithName:@"Menlo" size:11] ?: [NSFont userFixedPitchFontOfSize:11];
    textView.textContainer.containerSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    textView.textContainer.widthTracksTextView = NO;
    scrollView.documentView = textView;
    [box addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(box).offset(52);
        make.left.equalTo(box).offset(14);
        make.right.equalTo(box).offset(-14);
        make.bottom.equalTo(box).offset(-14);
    }];
    return textView;
}

#pragma mark - Validation

- (double)doubleFromField:(NSTextField *)field fallback:(double)fallback min:(double)min max:(double)max {
    double value = field.doubleValue;
    if (value < min || value > max) {
        return fallback;
    }
    return value;
}

- (NSInteger)integerFromField:(NSTextField *)field fallback:(NSInteger)fallback min:(NSInteger)min max:(NSInteger)max {
    NSInteger value = field.integerValue;
    if (value < min || value > max) {
        return fallback;
    }
    return value;
}

#pragma mark - Alerts

- (void)alertMsg:(NSString *)msg title:(NSString *)title {
    SMAlert *alert = [SMAlert alertWithTitle:title message:msg style:NSAlertStyleWarning];
    [alert addCommonButtonWithTitle:@"OK" handler:^(SMAlertItem * _Nonnull item) {
    }];
    [alert show:self.view.window];
}

@end
