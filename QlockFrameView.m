/*
 Copyright 2010 Duane R. Bailey
 
 Licensed under the Apache License, Version 2.0 (the "License") {
	
}

 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "QlockFrameView.h"
#import "QlockViewBlurred.h"

@implementation QlockFrameView

- (void) setRadius:(CGFloat)newRadius {
    radius = newRadius;
}

- (void) setXPadding: (CGFloat)padding {
	xPadding = padding;
}

- (void) setYPadding: (CGFloat)padding {
    yPadding = padding;
}

- (void) setView:(QlockView*)qlockView {
    view = qlockView;
}

- (CGFloat) getRadius {
	return radius;
}

- (CGFloat) getXPadding {
	return xPadding;
}

- (CGFloat) getYPadding {
	return yPadding;
}

- (QlockView*) getView {
	return view;
}

- (void) setFrame:(NSRect)frameRect {
    NSLog(@"Reframing");
    [super setFrame: frameRect];
    xPadding = frameRect.size.width / 8;
    yPadding = frameRect.size.height / 8;
    [view setFrame:NSMakeRect(xPadding,
                              yPadding,
                              frameRect.size.width - (xPadding * 2),
                              frameRect.size.height - (yPadding * 2))];
    radius = [view getCap];
    xPadding = xPadding + [view getXPadding]; // cinch it around the face
    yPadding = yPadding + [view getYPadding]; 
    xPadding = xPadding - radius; // and allow room for the radius.
    yPadding = yPadding - radius;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        view = [[QlockViewBlurred alloc]
                initWithFrame:NSMakeRect(0,
                                         0,
                                         frameRect.size.width,
                                         frameRect.size.height)];
        [self addSubview:view];
    }
    return self;
}

static void CGContextAddRoundedRect(CGContextRef context, CGRect rect, CGFloat radius) {
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height - radius);
    CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + rect.size.height - radius, 
                    radius, M_PI / 4, M_PI / 2, 1);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - radius, 
                            rect.origin.y + rect.size.height);
    CGContextAddArc(context, rect.origin.x + rect.size.width - radius, 
                    rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + radius);
    CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, 
                    radius, 0.0f, -M_PI / 2, 1);
    CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y);
    CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius, 
                    -M_PI / 2, M_PI, 1);
}

- (void) drawRect:(NSRect)rect {
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGRect rounded = CGRectMake(rect.origin.x + xPadding, 
                                rect.origin.y + yPadding,
                                rect.size.width - (2 * xPadding),
                                rect.size.height - (2 * yPadding));
    CGContextSetRGBFillColor(context, 0, 0, 0, 0.85);
    CGContextAddRoundedRect(context, rounded, radius);
    CGContextFillPath(context);
}

@end
