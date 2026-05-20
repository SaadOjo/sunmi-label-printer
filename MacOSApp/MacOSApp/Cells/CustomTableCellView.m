//
//  CustomTableCellView.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/20.
//

#import "CustomTableCellView.h"
#import "SMVerticallyCenteredTextField.h"

@interface CustomTableCellView ()

@property (nonatomic, strong) SMVerticallyCenteredTextField *label;
@property (nonatomic, strong) NSImageView *rssiImage;
@property (nonatomic, strong) NSImageView *lockImageView;

@end

@implementation CustomTableCellView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self addSubview:self.rssiImage];
        [self.rssiImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.equalTo(self.mas_right).offset(-20);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        
        [self addSubview:self.lockImageView];
        [self.lockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.equalTo(self.rssiImage.mas_left).offset(-5);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        
        [self addSubview:self.label];
        [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.mas_left).offset(20);
            make.size.mas_equalTo(CGSizeMake(200, 30));
        }];
    }
    return self;
}

- (NSImageView *)lockImageView {
    if (!_lockImageView) {
        _lockImageView = [[NSImageView alloc] init];
        _lockImageView.image = [NSImage imageNamed:@"wifi_list_cell_lock"];
    }
    return _lockImageView;
}

- (NSImageView *)rssiImage {
    if (!_rssiImage) {
        _rssiImage = [[NSImageView alloc] init];
        _rssiImage.image = [NSImage imageNamed:@"wifi_list_cell_wifi_4"];
    }
    return _rssiImage;
}

- (SMVerticallyCenteredTextField *)label {
    if (!_label) {
        _label = [[SMVerticallyCenteredTextField alloc] init];
        _label.textColor = [NSColor blackColor];
        _label.drawsBackground = NO;
        _label.bordered = NO;
        _label.enabled = NO;
        _label.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _label;
}

- (void)wifiName:(NSString *)name withPassword:(BOOL)hasPassword rssi:(NSString *)rssiNum {
    self.label.stringValue = name;
    self.lockImageView.hidden = !hasPassword;
    self.rssiImage.image = [NSImage imageNamed:[NSString stringWithFormat:@"wifi_list_cell_wifi_%@", rssiNum]];
}

- (void)setWifieName:(NSString *)wifieName {
    self.label.stringValue = wifieName;
}

- (void)setHasPassword:(BOOL)hasPassword {
    self.lockImageView.hidden = !hasPassword;
}

- (void)setRssiNum:(NSString *)rssiNum {
    self.rssiImage.image = [NSImage imageNamed:[NSString stringWithFormat:@"wifi_list_cell_wifi_%@", rssiNum]];
}

@end
