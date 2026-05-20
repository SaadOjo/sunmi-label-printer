//
//  SMVerticallyCenteredTextField.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/20.
//

#import "SMVerticallyCenteredTextField.h"
#import "SMVerticallyCenteredTextFieldCell.h"

@implementation SMVerticallyCenteredTextField

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.cell = [[SMVerticallyCenteredTextFieldCell alloc] initTextCell:@""];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
