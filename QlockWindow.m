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

#import "QlockWindow.h"
#import "CGSPrivate.h"
#import <Carbon/Carbon.h>



@implementation QlockWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag]) {
        [self setReleasedWhenClosed:YES];
    }
    return self;
}

- (BOOL) canBecomeKeyWindow {
    return FALSE;
}


// A method to basically disable expose for this window.
// Stolen from GeekTool, which I'm sure stole it from someone else.
- (void)setSticky:(BOOL)flag
{
    CGSConnection cid;
    CGSWindow wid;
    
    wid = [self windowNumber];
    cid = _CGSDefaultConnection();
    CGSWindowTag tags[2] = {0,0};   
    
    if(!CGSGetWindowTags(cid,wid,tags,32))
    {
        if (flag) tags[0] = tags[0] | 0x00000800;
        else tags[0] = tags[0] & ~0x00000800;
        CGSSetWindowTags(cid,wid,tags,32);
    }
}

// Ignore click events.
- (void)setClickThrough:(BOOL)clickThrough
{
    [self setIgnoresMouseEvents:clickThrough];
}

@end
