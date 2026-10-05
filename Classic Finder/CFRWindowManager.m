//
//  CFRWindowManager.m
//  Classic Finder
//
//  Created by Ben Szymanski on 3/25/17.
//  Copyright © 2017 Ben Szymanski. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "CFRWindowManager.h"
#import "CCIClassicFinderWindow.h"
#import "AppDelegate.h"
#import "CCIClassicFinderWindowController.h"
#import "CFRDirectoryModel.h"

@interface CFRWindowManager ()

@property (nonatomic, strong) NSMutableDictionary *activeWindows;
@property (nonatomic, strong) CCIClassicFinderWindowController *activeWindow;

@end

@implementation CFRWindowManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{
            @"CCIZoomRectAnimationsEnabled": @YES,
            @"CCISpringLoadedFoldersEnabled": @YES,
            @"CCISpringLoadedFolderDelay": @0.75
        }];
    }
    return self;
}

- (BOOL)zoomRectAnimationsEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"CCIZoomRectAnimationsEnabled"];
}

- (void)setZoomRectAnimationsEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"CCIZoomRectAnimationsEnabled"];
}

- (BOOL)springLoadedFoldersEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"CCISpringLoadedFoldersEnabled"];
}

- (void)setSpringLoadedFoldersEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"CCISpringLoadedFoldersEnabled"];
}

- (NSTimeInterval)springLoadedFolderDelay
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"CCISpringLoadedFolderDelay"];
}

- (void)setSpringLoadedFolderDelay:(NSTimeInterval)delay
{
    [[NSUserDefaults standardUserDefaults] setDouble:MAX(0.1, delay) forKey:@"CCISpringLoadedFolderDelay"];
}

- (NSRect)initialFrameForDirectory:(CFRDirectoryModel *)directoryModel relativeToWindow:(NSWindow *)parentWindow
{
    NSSize size = directoryModel.windowDimensions;
    BOOL hasUsableSavedSize = isfinite(size.width) && isfinite(size.height) &&
        size.width >= 200.0 && size.height >= 120.0;
    if (!hasUsableSavedSize) size = NSMakeSize(500.0, 300.0);

    NSPoint position = directoryModel.windowPosition;
    BOOL hasSavedPosition = isfinite(position.x) && isfinite(position.y) &&
        !(position.x == -1.0 && position.y == -1.0);
    if (!hasUsableSavedSize) hasSavedPosition = NO;
    if (!hasSavedPosition && parentWindow != nil) {
        position = NSMakePoint(NSMinX(parentWindow.frame) + 30.0, NSMaxY(parentWindow.frame) - size.height - 30.0);
    } else if (!hasSavedPosition) {
        NSScreen *mainScreen = NSScreen.mainScreen ?: NSScreen.screens.firstObject;
        NSRect visibleFrame = mainScreen != nil ? mainScreen.visibleFrame : NSMakeRect(0.0, 0.0, 1024.0, 768.0);
        position = NSMakePoint(NSMidX(visibleFrame) - size.width / 2.0,
                               NSMidY(visibleFrame) - size.height / 2.0);
    }

    NSRect frame = NSMakeRect(position.x, position.y, size.width, size.height);
    NSScreen *targetScreen = nil;
    CGFloat largestIntersection = 0.0;
    for (NSScreen *screen in NSScreen.screens) {
        NSRect intersection = NSIntersectionRect(frame, screen.visibleFrame);
        CGFloat area = NSIsEmptyRect(intersection) ? 0.0 : intersection.size.width * intersection.size.height;
        if (area > largestIntersection) {
            largestIntersection = area;
            targetScreen = screen;
        }
    }
    if (targetScreen == nil && parentWindow.screen != nil) targetScreen = parentWindow.screen;
    if (targetScreen == nil) targetScreen = NSScreen.mainScreen ?: NSScreen.screens.firstObject;
    NSRect visibleFrame = targetScreen != nil ? targetScreen.visibleFrame : NSMakeRect(0.0, 0.0, 1024.0, 768.0);

    frame.size.width = MIN(frame.size.width, visibleFrame.size.width);
    frame.size.height = MIN(frame.size.height, visibleFrame.size.height);
    NSRect titlebarRect = NSMakeRect(frame.origin.x, NSMaxY(frame) - 19.0, frame.size.width, 19.0);
    NSRect visibleTitlebarRect = NSIntersectionRect(titlebarRect, visibleFrame);
    CGFloat requiredTitlebarWidth = MIN(120.0, frame.size.width);
    if (visibleTitlebarRect.size.width < requiredTitlebarWidth || visibleTitlebarRect.size.height < 19.0) {
        CGFloat visibleWidth = MIN(120.0, visibleFrame.size.width);
        CGFloat minimumX = NSMinX(visibleFrame) - MAX(0.0, frame.size.width - visibleWidth);
        CGFloat maximumX = NSMaxX(visibleFrame) - visibleWidth;
        CGFloat maximumY = NSMaxY(visibleFrame) - 19.0;
        frame.origin.x = MIN(MAX(frame.origin.x, minimumX), maximumX);
        frame.origin.y = MIN(MAX(frame.origin.y, NSMinY(visibleFrame)), maximumY);
    }
    return frame;
}

+(CFRWindowManager *)sharedInstance
{
    static CFRWindowManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    if (sharedInstance != nil) {
        return sharedInstance;
    }
    
    dispatch_once(&pred, ^{
        sharedInstance = [CFRWindowManager alloc];
        sharedInstance = [sharedInstance init];
        sharedInstance.activeWindows = [[NSMutableDictionary alloc] initWithCapacity:30];
    });
    
    return sharedInstance;
}

- (CCIClassicFinderWindowController *)createWindowForDirectory:(CFRDirectoryModel *)directoryModel
{
    CCIClassicFinderWindowController *finderWindowController;

    NSString *directoryKey = directoryModel.objectPath.URLByStandardizingPath.absoluteString;
    if ([self.activeWindows objectForKey:directoryKey] != nil)
    {
        finderWindowController = [self.activeWindows objectForKey:directoryKey];
    } else
    {
        CCIClassicFinderWindowController *wc = [[CCIClassicFinderWindowController alloc] initForDirectory:directoryModel];
        
        [wc.window makeKeyAndOrderFront:self];
        
        finderWindowController = wc;
        
        [self.activeWindows setObject:wc
                               forKey:directoryKey];
    }
    
    return finderWindowController;
}

- (void)windowWillClose:(NSNotification *)notification
{
    CCIClassicFinderWindow *finderWindow = notification.object;
    CCIClassicFinderWindowController *finderWindowController = finderWindow.windowController;
    NSString *pathString = finderWindowController.directoryModel.objectPath.URLByStandardizingPath.absoluteString;
    
    [self.activeWindows removeObjectForKey:pathString];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    CCIClassicFinderWindow *finderWindow = notification.object;
    CCIClassicFinderWindowController *finderWindowController = finderWindow.windowController;
    
    self.activeWindow = finderWindowController;
}

- (NSUInteger)numberOfOpenWindows
{
    return [[self activeWindows] count];
}

@end
