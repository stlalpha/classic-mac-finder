//
//  AppDelegate.m
//  Classic Finder
//
//  Created by Ben Szymanski on 2/18/17.
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

#import "AppDelegate.h"
#import "CCIClassicFinderWindow.h"
#import "CCIClassicFinderWindowController.h"
#import "CFRWindowManager.h"
#import "CFRDirectoryModel.h"
#import "CFRFloppyDisk.h"
#import "CFRFileSystemUtils.h"
#import "CCIApplicationStyles.h"
#import <CoreText/CoreText.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (instancetype)init
{
    self = [super init];
    
    if (self)
    { }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    NSURL *fontURL = [[NSBundle mainBundle] URLForResource:@"chicagobold" withExtension:@"ttf"];
    if (fontURL != nil) {
        CTFontManagerRegisterFontsForURL((__bridge CFURLRef)fontURL, kCTFontManagerScopeProcess, NULL);
    }
    
    [self openRootVolumeWindow];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    CFRWindowManager *windowManager = [CFRWindowManager sharedInstance];
    
    if ([windowManager numberOfOpenWindows] == 0) {
        [self openRootVolumeWindow];
    }
}

// Inspiration for the following two methods comes from:
// http://www.cocoabuilder.com/archive/cocoa/238362-how-to-detect-click-on-app-dock-icon-when-the-app-is-active.html

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender
{
    CFRWindowManager *windowManager = [CFRWindowManager sharedInstance];
    
    if ([windowManager numberOfOpenWindows] == 0) {
        [self openRootVolumeWindow];
    }
    
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    for (NSWindow *window in NSApp.windows) {
        if (![window isKindOfClass:CCIClassicFinderWindow.class]) continue;
        [(CCIClassicFinderWindowController *)window.windowController persistSpatialState];
    }
}

- (void)openRootVolumeWindow
{
    NSURL *rootDirectoryPath = [NSURL fileURLWithPath:@"/"];
    CFRDirectoryModel *rootDirectoryModel = [[CFRDirectoryModel alloc] init];
    rootDirectoryModel.objectPath = rootDirectoryPath;
    rootDirectoryModel.title = [CFRFileSystemUtils determineDirectoryNameForURL:rootDirectoryPath];

    NSError *error = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:rootDirectoryPath.path error:&error];
    rootDirectoryModel.fileSystemNumber = [fileAttributes[NSFileSystemNumber] unsignedLongLongValue];

    [CFRFloppyDisk restoreDirectoryProperties:rootDirectoryModel];
    NSRect initialFrame = [CFRWindowManager.sharedInstance initialFrameForDirectory:rootDirectoryModel relativeToWindow:nil];
    rootDirectoryModel.windowPosition = initialFrame.origin;
    rootDirectoryModel.windowDimensions = initialFrame.size;
    [CFRFloppyDisk persistDirectoryProperties:rootDirectoryModel];

    CCIClassicFinderWindowController *finderWindow = [CFRWindowManager.sharedInstance createWindowForDirectory:rootDirectoryModel];
    [finderWindow showWindow:self];
    self.window = finderWindow.window;
}

- (void)applyViewStyle:(NSString *)style
{
    CCIClassicFinderWindow *window = (CCIClassicFinderWindow *)NSApp.keyWindow;
    if ([window isKindOfClass:CCIClassicFinderWindow.class]) [window setDisplayStyle:style];
}

- (void)showBySmallIcon:(id)sender { [self applyViewStyle:@"Small Icon"]; }
- (void)showAsButtons:(id)sender { [self applyViewStyle:@"Buttons"]; }
- (void)showByIcon:(id)sender { [self applyViewStyle:@"Icon"]; }
- (void)showByName:(id)sender { [self applyViewStyle:@"Name"]; }
- (void)showBySize:(id)sender { [self applyViewStyle:@"Size"]; }
- (void)showByKind:(id)sender { [self applyViewStyle:@"Kind"]; }
- (void)showByLabel:(id)sender { [self applyViewStyle:@"Label"]; }
- (void)showByDate:(id)sender { [self applyViewStyle:@"Date"]; }

- (void)applyAppearanceVersion:(CCIClassicAppearanceVersion)version
{
    [CCIApplicationStyles.instance setAppearanceVersion:version];
    for (NSWindow *window in NSApp.windows) [self markViewTreeForRedraw:window.contentView];
}

- (void)markViewTreeForRedraw:(NSView *)view
{
    [view setNeedsDisplay:YES];
    for (NSView *child in view.subviews) [self markViewTreeForRedraw:child];
}

- (void)useSystem7Appearance:(id)sender { [self applyAppearanceVersion:CCIClassicAppearanceSystem7]; }
- (void)useMacOS9Appearance:(id)sender { [self applyAppearanceVersion:CCIClassicAppearanceMacOS9]; }

- (void)toggleZoomRectAnimations:(id)sender
{
    CFRWindowManager *manager = CFRWindowManager.sharedInstance;
    manager.zoomRectAnimationsEnabled = !manager.zoomRectAnimationsEnabled;
}

- (void)toggleSpringLoadedFolders:(id)sender
{
    CFRWindowManager *manager = CFRWindowManager.sharedInstance;
    manager.springLoadedFoldersEnabled = !manager.springLoadedFoldersEnabled;
}

- (void)setSpringLoadedFolderDelay:(id)sender
{
    CFRWindowManager.sharedInstance.springLoadedFolderDelay = [sender tag] / 100.0;
}

- (void)applyLabelIndex:(NSInteger)labelIndex
{
    CCIClassicFinderWindow *window = (CCIClassicFinderWindow *)NSApp.keyWindow;
    if ([window isKindOfClass:CCIClassicFinderWindow.class]) [window applyLabelIndex:labelIndex];
}

- (void)setLabelNone:(id)sender { [self applyLabelIndex:0]; }
- (void)setLabelEssential:(id)sender { [self applyLabelIndex:1]; }
- (void)setLabelHot:(id)sender { [self applyLabelIndex:2]; }
- (void)setLabelInProgress:(id)sender { [self applyLabelIndex:3]; }
- (void)setLabelCool:(id)sender { [self applyLabelIndex:4]; }
- (void)setLabelPersonal:(id)sender { [self applyLabelIndex:5]; }
- (void)setLabelProject1:(id)sender { [self applyLabelIndex:6]; }
- (void)setLabelProject2:(id)sender { [self applyLabelIndex:7]; }

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = menuItem.action;
    if (action == @selector(useSystem7Appearance:)) menuItem.state = CCIApplicationStyles.instance.appearanceVersion == CCIClassicAppearanceSystem7;
    else if (action == @selector(useMacOS9Appearance:)) menuItem.state = CCIApplicationStyles.instance.appearanceVersion == CCIClassicAppearanceMacOS9;
    else if (action == @selector(toggleZoomRectAnimations:)) menuItem.state = CFRWindowManager.sharedInstance.zoomRectAnimationsEnabled;
    else if (action == @selector(toggleSpringLoadedFolders:)) menuItem.state = CFRWindowManager.sharedInstance.springLoadedFoldersEnabled;
    else if (action == @selector(setSpringLoadedFolderDelay:)) menuItem.state = fabs(CFRWindowManager.sharedInstance.springLoadedFolderDelay - (menuItem.tag / 100.0)) < 0.01;
    else {
        NSDictionary<NSString *, NSString *> *viewActions = @{
            NSStringFromSelector(@selector(showByIcon:)): @"Icon",
            NSStringFromSelector(@selector(showBySmallIcon:)): @"Small Icon",
            NSStringFromSelector(@selector(showAsButtons:)): @"Buttons",
            NSStringFromSelector(@selector(showByName:)): @"Name",
            NSStringFromSelector(@selector(showBySize:)): @"Size",
            NSStringFromSelector(@selector(showByKind:)): @"Kind",
            NSStringFromSelector(@selector(showByLabel:)): @"Label",
            NSStringFromSelector(@selector(showByDate:)): @"Date"
        };
        NSString *style = viewActions[NSStringFromSelector(action)];
        CCIClassicFinderWindow *window = (CCIClassicFinderWindow *)NSApp.keyWindow;
        if (style != nil && [window isKindOfClass:CCIClassicFinderWindow.class]) menuItem.state = [window.displayStyle isEqualToString:style];
        else return YES;
    }
    return YES;
}

@end
