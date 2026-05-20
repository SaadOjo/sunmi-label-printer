//
//  SMTableViewCell.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/13.
//

#import "SMTableViewCell.h"
#import "SMVerticallyCenteredTextField.h"

@interface SMTableViewCell ()

@property (nonatomic, strong) SMVerticallyCenteredTextField *label;

@end

@implementation SMTableViewCell

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.label];
        [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self).offset(20);
            make.size.mas_equalTo(CGSizeMake(200, 30));
        }];
    }
    return self;
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

- (void)setDeviceNameString:(NSString *)deviceNameString {
    self.label.stringValue = deviceNameString;
}

@end
