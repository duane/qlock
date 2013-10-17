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
 QlockView.m  provides an the interface for the Cocoa view QlockView.
 
 Currently, the class works with raw glyphs because it's the easiest for the
 purposes of the application; currently, I cheat and hardwire in an apostrophe
 for the "O'CLOCK" because it looks cool and I was too tired last night to work
 up something more elegant. The logic is also very rough; I'd like to provide
 something more elegant in the long run, but it currently works, and works
 excellently. So: mission accomplished.
 
 TODO: Split code off into a separation of Display/Logic.
 
 TODO: Load in currently static data (font, colors, text, etc) from file.
 
 TODO: Provide a more elegant interface to define the clock face text (with
       regards to contractions) and clock states.
 
 TODO: Work up a preferences GUI to manipulate the common variables.
 
 TODO: Provide variability in how the idioms are defined. For example: 3:57
       could either be "three o'clock" or "five to three"; provide an interface
       for "pessimistic", "average", and "optimistic" times.
 */

#import "QlockView.h"
#import <stdio.h>
#import <stdbool.h>

static const unsigned CLOCK_WIDTH = 11;
static const unsigned CLOCK_HEIGHT = 10;
#define DEFAULT_FONT "Helvetica"

static float capPadding = 1.0; // 1 unit of cap height is kept between the characters and the top, vertically, at all times.
static float emPadding = 1.0; // 1 em of width is kept between the characters and the sides, horizontally, at all times.


#define IT active[0] = TRUE; active[1] = TRUE;
#define IS active[3] = TRUE; active[4] = TRUE;
#define FIVE active[28] = TRUE; active[29] = TRUE; active[30] = TRUE; active[31] = TRUE; active[31] = TRUE;
#define TEN active[38] = TRUE; active[39] = TRUE; active[40] = TRUE;
#define AQUARTER active[11] = TRUE; active[13] = TRUE; active[14] = TRUE; active[15] = TRUE; active[16] = TRUE; active[17] = TRUE; active[18] = TRUE; active[19] = TRUE;
#define TWENTY active[22] = TRUE; active[23] = TRUE; active[24] = TRUE; active[25] = TRUE; active[26] = TRUE; active[27] = TRUE;
#define HALF active[33] = TRUE; active[34] = TRUE; active[35] = TRUE; active[36] = TRUE;

#define PAST active[44] = TRUE; active[45] = TRUE; active[46] = TRUE; active[47] = TRUE;
#define TO active[42] = TRUE; active[43] = TRUE;
#define OCLOCK active[104] = TRUE; active[105] = TRUE; active[106] = TRUE; active[107] = TRUE; active[108] = TRUE; active[109] = TRUE;


@implementation QlockView

static void printNSRect(NSRect rect) {
    printf("((%f, %f), (%f, %f))\n",
           rect.origin.x,
           rect.origin.y,
           rect.size.width,
           rect.size.height);
}

- (void) printMetrics {
    NSRect frame = [self frame];
    printf("em: %f\n"
           "point: %f\n"
           "xHeight: %f\n"
           "cap: %f\n"
           "x padding: %f\n"
           "y padding: %f\n"
           "face width: %f\n"
           "face height: %f\n"
           "frame: ",
           em, point, xHeight, cap, xPadding, yPadding, width, height);
    printNSRect(frame);
}

- (id) initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        glyphs = NULL;
        boundingBoxes = NULL;
        paths = NULL;
        fontName = [NSString stringWithUTF8String: DEFAULT_FONT];
        [self setFont: [NSFont fontWithName:fontName size:12.0]]; // a suitable default font.

        // now we set the active
        active = malloc(numGlyphs * sizeof(BOOL));
        for (int i = 0; i < numGlyphs; i++)
            active[i] = FALSE;
        
        //IT IS TWENTY FIVE PAST active[82] = TRUE; active[83] = TRUE; active[84] = TRUE; active[85] = TRUE; active[86] = TRUE; active[87] = TRUE;
        // and initiate the clock timer
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar
                                        components: NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                                        fromDate:date];
        [self updateClockForHour: [components hour] forMinute: [components minute]]; // set it to the current time.
        
        // now start the timer
        NSDateComponents *diff = [[[NSDateComponents alloc] init] autorelease];
        [diff setSecond: 60 - [components second]];
        NSDate *fireDate = [calendar dateByAddingComponents:diff toDate:date options:0];
        timer = [[NSTimer alloc] initWithFireDate:fireDate
                                          interval:60
                                            target:self
                                          selector:@selector(fireClockUpdate:)
                                          userInfo:nil
                                           repeats:TRUE];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        [self printMetrics];
    }  
    return self;
}

- (void) calculateFontMetrics {
    NSRect frame = [self frame];
    unichar m = [@"m" characterAtIndex: 0];
    CTFontGetGlyphsForCharacters(font, &m, &emGlyph, 1);
    CGRect emBox = CTFontGetBoundingRectsForGlyphs(font,
                                                   kCTFontHorizontalOrientation, 
                                                   &emGlyph,
                                                   NULL,
                                                   1);
    
    em = emBox.size.width;
    cap = CTFontGetCapHeight(font);
    xHeight = CTFontGetXHeight(font);
    
    width = em * (CLOCK_WIDTH + ((CLOCK_WIDTH + 1) * emPadding));
    height = cap * (CLOCK_HEIGHT + ((CLOCK_HEIGHT + 1) * capPadding));
    xPadding = ((frame.size.width) - width) / 2;
    yPadding = ((frame.size.height) - height) / 2;
}

- (void) resizeFont {
    // pretty simple, just adjust for frame changes.
    NSRect frame = [self frame];
    [self calculateFontMetrics];
    
    // scale the font so that whichever size is more cramped decides the scale
    // of the font as a whole
    CGFloat xScale = frame.size.width / width;
    CGFloat yScale = frame.size.height / height;
    CGFloat scale = xScale < yScale ? xScale : yScale;
    
    point = point * scale; // scale the point up to the new size.
    // and reload the font.
    
    CFRelease(font);
    font = CTFontCreateWithName((CFStringRef)fontName, point, NULL);
    
    // regather the font metrics.
    [self calculateFontMetrics];
    
    // Whoo! We've found a good point for the font to use for the given frame.
    [self prepareGlyphs];
}

- (void)prepareGlyphs {
    // Now let's get the bounding box information for each glyph, used for positioning.
    if(!boundingBoxes)
        boundingBoxes = malloc(sizeof(CGRect) * numGlyphs);
    if (CGRectIsNull(CTFontGetBoundingRectsForGlyphs(font,
                                                     kCTFontHorizontalOrientation,
                                                     glyphs,
                                                     boundingBoxes,
                                                     numGlyphs))) {
        NSLog(@"Unable to find the information for all glyphs; some glyphs may"
              " not render correctly.");
    }
    // now we make the paths
    if (!paths)
        paths = malloc(numGlyphs * sizeof(CGPathRef));
    for (int i = 0; i < numGlyphs; i++) {
        CGPathRef path = CTFontCreatePathForGlyph(font, glyphs[i], NULL);
        if (i == 104) {
            unichar apostrophe = [@"'" characterAtIndex:0];
            CGGlyph apostropheGlyph;
            CTFontGetGlyphsForCharacters(font, &apostrophe, &apostropheGlyph, 1);
            CGPathRef apostrophePath;
            apostrophePath = CTFontCreatePathForGlyph(font, apostropheGlyph, NULL);
            CGAffineTransform transform = CGAffineTransformMakeTranslation(boundingBoxes[i].size.width, 0);
            CGMutablePathRef sum = CGPathCreateMutableCopy(path);
            CGPathAddPath(sum, &transform, apostrophePath);
            paths[i] = sum;
        } else 
            paths[i] = path;
    }
}

- (void) setFont:(NSFont*)newFont {
    font = (CTFontRef)newFont;
    fontName = [newFont fontName]; // used for reloading the font of another size later.
    point = CTFontGetSize(font);
    
    // Now we fetch the glyphs, which are font-specific
    // the bright side is that we only need to fetch them when we set a typeface!
    char ascii[] = "ITLISASTIMEACQUARTERDCTWENTYFIVEXHALFBTENFTOPASTERUNINEONESIXTHREEFOURFIVETWOEIGHTELEVENSEVENTWELVETENSEOCLOCK";
    numGlyphs = sizeof(ascii) - 1;
    unichar *chars = malloc(sizeof(unichar) * numGlyphs);
    if (!glyphs)
        glyphs = malloc(sizeof(CGGlyph) * numGlyphs);
    NSString *charBuffer = [NSString  stringWithUTF8String: ascii];
    [charBuffer getCharacters:chars range:NSMakeRange(0, numGlyphs)];
    if (!CTFontGetGlyphsForCharacters(font, chars, glyphs, numGlyphs)) {
        //printf("Aww man, we couldn't get gylphs for the characters. :(\n");
        
    }
    free(chars);
    
    [self resizeFont];
}

- (NSFont*) getFont {
	return (NSFont*)font; // I *love* toll-free bridging.
}


- (CGFloat) getCap {
	return cap;
}

- (CGFloat) getXHeight {
	return xHeight;
}

- (CGFloat) getEm {
	return em;
}

- (CGFloat) getPoint {
	return point;
}

- (CGFloat) getFaceWidth {
    return width;
}

- (CGFloat) getFaceHeight {
    return height;
}

- (CGFloat) getXPadding {
    return xPadding;
}

- (CGFloat) getYPadding {
    return yPadding;    
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    [self resizeFont];
    [self printMetrics];
}

- (void) renderGlyphsForContext:(CGContextRef)context withFrame:(NSRect)rect  drawInactive:(BOOL)inactive {
    for (size_t i = 0; i < numGlyphs; i++) {
        if (!inactive && !active[i])
            continue;
        size_t xPos = (i % CLOCK_WIDTH);
        size_t yPos = (i / CLOCK_WIDTH);
        CGFloat x = em * (xPos  + ((xPos + 1) * emPadding)) + xPadding;
        CGFloat y = rect.size.height - ((cap * (yPos + ((yPos + 1) * capPadding))) + yPadding);
        
        // now we center it.
        CGRect frame = boundingBoxes[i];
        x = x - (frame.size.width / 2) + (em / 2);
        y = y - (cap); // we use `cap` instead of the glyph's height for a solid baseline
        
        // and draw it.
        if (active[i])
            CGContextSetRGBFillColor(context, 1, 1, 1, 1);
        else
            CGContextSetRGBFillColor(context, 0.25, 0.25, 0.25, 1);
        
        CGContextMoveToPoint(context, x, y);
        CGMutablePathRef path = CGPathCreateMutable();
        CGAffineTransform trans = CGAffineTransformMakeTranslation(x, y);
        CGPathAddPath(path, &trans, paths[i]);
        CGContextAddPath(context, path);
        CGContextFillPath(context);
        CFRelease(path);
    }
}

- (void) drawRect:(NSRect)rect {
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    [self renderGlyphsForContext:context withFrame:rect drawInactive:TRUE];
}

- (void) fireClockUpdate:(NSTimer*)theTimer {
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar
                                    components: NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                                    fromDate:date];
    //printf("%lu %lu\n", [components hour], [components minute]);
    [self updateClockForHour: [components hour] forMinute: [components minute]]; // set it to the current time.
    // aaaand that's it.
}

- (void) updateClockForHour:(NSUInteger) hour forMinute:(NSUInteger) minute {
    for (int i = 0; i < numGlyphs; i++)
        active[i] = FALSE;
    
    if (minute >= 35)
        hour += 1; // TO hour
    hour = hour % 12; // 12 hour clock
    minute = minute / 5;
    
    switch (minute) {
        default:
        case 0:
            IT IS /*NUMBER */ OCLOCK
            break;
        case 1:
            IT IS FIVE PAST
            break;
        case 2:
            IT IS TEN PAST
            break;
        case 3:
            IT IS AQUARTER PAST
            break;
        case 4:
            IT IS TWENTY PAST
            break;
        case 5:
            IT IS TWENTY FIVE PAST
            break;
        case 6:
            IT IS HALF PAST
            break;
        case 7:
            IT IS TWENTY FIVE TO
            break;
        case 8:
            IT IS TWENTY TO
            break;
        case 9:
            IT IS AQUARTER TO
            break;
        case 10:
            IT IS TEN TO
            break;
        case 11:
            IT IS FIVE TO
            break;
    }
    
    switch (hour) {
        case 0:
            active[93] = TRUE; active[94] = TRUE; active[95] = TRUE; active[96] = TRUE; active[97] = TRUE; active[98] = TRUE;
            break;
        case 1:
            active[55] = TRUE; active[56] = TRUE; active[57] = TRUE;
            break;
        case 2:
            active[74] = TRUE; active[75] = TRUE; active[76] = TRUE;
            break;
        case 3:
            active[61] = TRUE; active[62] = TRUE; active[63] = TRUE; active[64] = TRUE; active[65] = TRUE;
            break;
        case 4:
            active[66] = TRUE; active[67] = TRUE; active[68] = TRUE; active[69] = TRUE;
            break;
        case 5:
            active[70] = TRUE; active[71] = TRUE; active[72] = TRUE; active[73] = TRUE;
            break;
        case 6:
            active[58] = TRUE; active[59] = TRUE; active[60] = TRUE;
            break;
        case 7:
            active[88] = TRUE; active[89] = TRUE; active[90] = TRUE; active[91] = TRUE; active[92] = TRUE;
            break;
        case 8:
            active[77] = TRUE; active[78] = TRUE; active[79] = TRUE; active[80] = TRUE; active[81] = TRUE;
            break;
        case 9:
            active[51] = TRUE; active[52] = TRUE; active[53] = TRUE; active[54] = TRUE;
            break;
        case 10:
            active[99] = TRUE; active[100] = TRUE; active[101] = TRUE;
            break;
        case 11:
            active[82] = TRUE; active[83] = TRUE; active[84] = TRUE; active[85] = TRUE; active[86] = TRUE; active[87] = TRUE;
            break;
    }
    [[self superview] setNeedsDisplay:TRUE]; // redraw the parent
}


- (void) dealloc {
    if (glyphs)
        free(glyphs);
    if (boundingBoxes)
        free(boundingBoxes);
    if (paths)
        free(paths);
    if (font)
        CFRelease(font);
    if (timer)
        [timer release];
    [super dealloc];
}

@end
