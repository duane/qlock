//
//  ScreenSaverView.m
//  ScreenSaver
//
//  Created by Duane Bailey on 11/6/10.
//  Copyright (c) 2010, __MyCompanyName__. All rights reserved.
//

#import "QScreenSaverView.h"
#import "QlockViewBlurred.h"

@implementation QScreenSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        view = [[QlockView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:view];
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    // fill in the background.
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
}

- (void)animateOneFrame
{
    [self setNeedsDisplay:TRUE];
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

- (void)dealloc {
    [view release];
    [super dealloc];
}

@end
