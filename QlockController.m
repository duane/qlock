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

#import "QlockController.h"


@implementation QlockController

- (void)awakeFromNib {
    NSLog(@"I have awoken.");
    // now let's set up our status item.
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    statusItem = [[bar statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setTitle:@"Q"];
    [statusItem setMenu: menu];
   
    NSRect screenRect = [[NSScreen mainScreen] frame];
    screenRect.size.height = screenRect.size.height - [bar thickness];
    window = [[[QlockWindow alloc] initWithContentRect:screenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:TRUE] retain];
    view = [[QlockFrameView alloc] initWithFrame:[window contentRectForFrameRect:screenRect]];
    [window setContentView:view];
    [window setLevel:kCGDesktopWindowLevel];
    [window setSticky:TRUE];
    [window setOpaque:FALSE];
    [window setBackgroundColor:[NSColor clearColor]];
    [window makeKeyAndOrderFront:self];
    [window orderBack:self];
}

- (void) dealloc {
    [statusItem release];
    NSLog(@"Deallocating.");
    [super dealloc];
}

@end
