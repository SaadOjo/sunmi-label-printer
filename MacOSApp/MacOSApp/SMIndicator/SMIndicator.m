//
//  SMIndicator.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/17.
//

#import "SMIndicator.h"

@interface SMIndicator ()

@property (nonatomic, strong) NSProgressIndicator *indicator;

@end

@implementation SMIndicator

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = SM_COLORHEX(0x000000, 0.3).CGColor;
        self.layer.cornerRadius = 10;
        
        [self addSubview:self.indicator];
        [self.indicator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];
        
        self.hidden = YES;
    }
    return self;
}

- (NSProgressIndicator *)indicator {
    if (!_indicator) {
        _indicator = [[NSProgressIndicator alloc] init];
        _indicator.style = NSProgressIndicatorStyleSpinning;
        _indicator.controlSize = NSControlSizeRegular;
        [_indicator sizeToFit];
    }
    return _indicator;
}

- (void)show {
    self.hidden = NO;
    [self.indicator startAnimation:nil];
}

- (void)dismiss {
    self.hidden = YES;
    [self.indicator stopAnimation:nil];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
