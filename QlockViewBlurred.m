//
//  QlockViewBlurred.m
//  Qlock
//
//  Created by Duane Bailey on 11/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QlockViewBlurred.h"


@implementation QlockViewBlurred

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(NSRect)frame {
    // Drawing code here.
    CGRect rect = CGRectMake(0, 0, frame.size.width, frame.size.height);
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CIContext *ciContext = [[[NSGraphicsContext currentContext] CIContext] retain];
    if (!ciContext) {
        ciContext = [CIContext contextWithCGContext:
                   [[NSGraphicsContext currentContext] graphicsPort]
                                            options: nil];
        [ciContext retain];
    }
    // first, render the glyphs normally to an off-screen buffer.
    CGLayerRef layer = CGLayerCreateWithContext(context, rect.size, NULL);
    [self renderGlyphsForContext:CGLayerGetContext(layer) withFrame:frame drawInactive:FALSE];
    CIImage *image = [CIImage imageWithCGLayer:layer];
    CGLayerRelease(layer);
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue: image forKey: @"inputImage"];
    [filter setValue: [NSNumber numberWithDouble:7.5] forKey: @"inputRadius"];
    CIImage *result = [filter valueForKey:@"outputImage"];
    
    
    // now draw the buffer to screen
    [ciContext drawImage:result atPoint:CGPointZero fromRect:rect];
    [ciContext release];
    
    // and draw the original glyphs.
    [self renderGlyphsForContext:context withFrame:frame drawInactive:TRUE];
}

@end
