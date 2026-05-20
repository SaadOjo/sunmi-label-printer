//
//  EmptyRefreshView.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/16.
//

#import "EmptyRefreshView.h"

@interface EmptyRefreshView ()

@property (nonatomic, strong) NSImageView *logoImageView;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *contentLabel;
@property (nonatomic, strong) SYFlatButton *refreshButton;

@end

@implementation EmptyRefreshView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // logo
        [self addSubview:self.logoImageView];
        [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.centerX.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(100, 100));
        }];
        
        // tip1
        [self addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.logoImageView.mas_bottom).offset(16);
            make.left.equalTo(self).offset(25.0f);
            make.right.equalTo(self).offset(-25.0f);
        }];
        
        // tip2
        [self addSubview:self.contentLabel];
        [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
            make.left.equalTo(self).offset(25.0f);
            make.right.equalTo(self).offset(-25.0f);
        }];
        
        // 刷新按钮
        [self addSubview:self.refreshButton];
        [self.refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.offset(0);
            make.top.equalTo(self.contentLabel.mas_bottom).offset(24);
            make.width.offset(104);
            make.height.offset(36);
        }];
    }
    return self;
}

- (void)setLogo:(NSString *)logoString {
    self.logoImageView.image = [NSImage imageNamed:logoString];
}

- (void)setTip_up:(NSString *)tip_1_string {
    self.titleLabel.stringValue = tip_1_string;
}

- (void)setTip_down:(NSString *)tip_2_string {
    self.contentLabel.stringValue = tip_2_string;
}

- (NSImageView *)logoImageView {
    if (!_logoImageView) {
        _logoImageView = [[NSImageView alloc] init];
    }
    return _logoImageView;
}

- (NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NSTextField alloc] init];
        _titleLabel.editable = NO;
        _titleLabel.bordered = NO;
        _titleLabel.backgroundColor = [NSColor clearColor];
        _titleLabel.textColor = COLOR_33;
        _titleLabel.maximumNumberOfLines = 0;
        _titleLabel.font = [NSFont systemFontOfSize:20];
        _titleLabel.alignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (NSTextField *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[NSTextField alloc] init];
        _contentLabel.editable = NO;
        _contentLabel.bordered = NO;
        _contentLabel.textColor = COLOR_85;
        _contentLabel.backgroundColor = [NSColor clearColor];
        _contentLabel.font = [NSFont systemFontOfSize:12 weight:NSFontWeightLight];
        _contentLabel.maximumNumberOfLines = 0;
        _contentLabel.alignment = NSTextAlignmentCenter;
    }
    return _contentLabel;
}

- (SYFlatButton *)refreshButton {
    if (!_refreshButton) {
        _refreshButton = [[SYFlatButton alloc] init];
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

- (void)refreshButtonclick {
    if (self.refreshBlock) {
        self.refreshBlock();
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
