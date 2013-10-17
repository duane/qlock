/*
 Copyright 2010 Duane R. Bailey
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

/*
    QlockView.h provides an interface for the Cocoa view QlockView.
 */

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <ScreenSaver/ScreenSaver.h>

@interface QlockView : NSView {
    CGGlyph emGlyph, *glyphs;
    CGPathRef *paths;
    CTFontRef font;
    CGRect *boundingBoxes;
    size_t numGlyphs;
    CGFloat em, point, xHeight, cap;
    CGFloat xPadding, yPadding, width, height;
    NSString *fontName;
    BOOL *active;
    
    NSTimer *timer;
}
- (void) updateClockForHour:(NSUInteger) hour forMinute:(NSUInteger) minute;

- (void) setFont:(NSFont*)newFont;

- (NSFont*) getFont;
- (CGFloat) getCap;
- (CGFloat) getXHeight;
- (CGFloat) getEm;
- (CGFloat) getPoint;
- (CGFloat) getFaceWidth;
- (CGFloat) getFaceHeight;
- (CGFloat) getXPadding;
- (CGFloat) getYPadding;

- (void) calculateFontMetrics; // for internal use.
- (void) fireClockUpdate:(NSTimer*) theTimer;
- (void) resizeFont;
- (void) prepareGlyphs;
- (void) renderGlyphsForContext:(CGContextRef)context withFrame:(NSRect)frame drawInactive:(BOOL)inactive;

@end
