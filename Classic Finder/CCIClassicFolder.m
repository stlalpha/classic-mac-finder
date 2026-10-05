//
//  CCIClassicFolder.m
//  Classic Finder
//
//  Created by Ben Szymanski on 2/19/17.
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

#import "CCIClassicFolder.h"
#import "CCIClassicFolderIcon.h"
#import "CFRWindowManager.h"
#import "AppDelegate.h"
#import "CCIClassicFinderWindow.h"
#import "CCIClassicFinderWindowController.h"
#import "CCIApplicationStyles.h"
#import "CFRFloppyDisk.h"
#import "CFRDirectoryModel.h"

static NSString *CCITruncatedIconTitle(NSString *title, NSFont *font, CGFloat maxWidth)
{
    if (title.length == 0) return @"";
    NSDictionary *attributes = @{NSFontAttributeName: font};
    NSString *display = title;
    while (display.length > 0 && [[display stringByAppendingString:@"…"] sizeWithAttributes:attributes].width > maxWidth) {
        NSRange lastCharacter = [display rangeOfComposedCharacterSequenceAtIndex:display.length - 1];
        display = [display stringByReplacingCharactersInRange:lastCharacter withString:@""];
    }
    return display.length == title.length ? title : [display stringByAppendingString:@"…"];
}

@interface CCIClassicFolder ()

@property (nonatomic, copy) NSString *folderTitle;
@property (nonatomic, strong) CCIClassicFolderIcon *iconImage;

@property BOOL folderSelected;
@property BOOL folderOpened;
@property NSPoint dragStartLocation;
@property NSRect dragStartFrame;

@end

@implementation CCIClassicFolder

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        [self setFolderSelected:NO];
        [self setFolderOpened:NO];
        
        NSRect folderIconFrame = NSMakeRect(14.5, 2.0, 31.0, 25.0);
        self.iconImage = [[CCIClassicFolderIcon alloc] initWithFrame:folderIconFrame];
        
        [self addSubview:self.iconImage];
        
        NSRect folderLabelFrame = NSMakeRect(-7.5, 35.0, 75.0, 24.0);
        self.folderLabel = [[NSTextField alloc] initWithFrame:folderLabelFrame];
        self.folderLabel.alignment = NSTextAlignmentCenter;
        self.folderLabel.font = [[CCIApplicationStyles instance] classicBodyFontOfSize:10.0];
        self.folderLabel.bordered = NO;
        self.folderLabel.selectable = NO;
        self.folderLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.folderLabel.drawsBackground = NO;
        self.folderLabel.maximumNumberOfLines = 1;
        self.folderLabel.usesSingleLineMode = YES;

        [self normalFolderTitleTextColor];
        
        [self addSubview:self.folderLabel];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appearanceDidChange:) name:@"CCIClassicAppearanceDidChange" object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appearanceDidChange:(NSNotification *)notification
{
    self.folderLabel.font = [[CCIApplicationStyles instance] classicBodyFontOfSize:10.0];
    [self setFolderTitleText:self.directoryModel.title ?: @""];
    if (self.folderSelected) [self reverseFolderTitleTextColor];
    else [self normalFolderTitleTextColor];
    [self.iconImage setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    // Drawing code here.
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)mouseDown:(NSEvent *)event
{
    CCIClassicFinderWindowController *wc = event.window.windowController;
    self.dragStartLocation = [self.superview convertPoint:event.locationInWindow fromView:nil];
    self.dragStartFrame = self.frame;
    [wc selectedNewFolder:self];
}

- (void)mouseDragged:(NSEvent *)event
{
    NSPoint point = [self.superview convertPoint:event.locationInWindow fromView:nil];
    NSRect frame = self.dragStartFrame;
    frame.origin.x += point.x - self.dragStartLocation.x;
    frame.origin.y += point.y - self.dragStartLocation.y;
    [(CCIClassicFinderWindowController *)event.window.windowController moveIconView:self toFrame:frame];
}

- (void)mouseUp:(NSEvent *)event
{
    if (event.clickCount == 2)
    {
        [CFRFloppyDisk restoreDirectoryProperties:[self directoryModel]];
        
        NSSize persistedWindowDimensions = [[self directoryModel] windowDimensions];
        NSSize safeWindowDimensions = persistedWindowDimensions;
        
        if (persistedWindowDimensions.width < 0.0) {
            safeWindowDimensions = NSMakeSize(500.0, persistedWindowDimensions.height);
            [[self directoryModel] setWindowDimensions:safeWindowDimensions];
            [CFRFloppyDisk persistDirectoryProperties:[self directoryModel]];
        }
        
        if (persistedWindowDimensions.height < 0.0) {
            safeWindowDimensions = NSMakeSize(safeWindowDimensions.width, (safeWindowDimensions.width * 0.6));
            [[self directoryModel] setWindowDimensions:safeWindowDimensions];
            [CFRFloppyDisk persistDirectoryProperties:[self directoryModel]];
        }
        
        
        NSPoint persistedWindowPosition = [[self directoryModel] windowPosition];
        
        if ((persistedWindowPosition.x == -1.0) &&
            (persistedWindowPosition.y == -1.0))
        {
            // We assume the window position hasn't been
            // previously set if windowPosition = (-1, -1).
            // We will just do a generic offset of 30 px
            // from the parent/calling window...
            
            NSRect windowFrame = event.window.frame;
            CGFloat xPos = windowFrame.origin.x + 30.0;
            CGFloat yPos = windowFrame.origin.y - 30.0;
            
            NSPoint newWindowPosition = NSMakePoint(xPos, yPos);
            [[self directoryModel] setWindowPosition:newWindowPosition];
        } else {
            // Handle overflow
            // if the last-recorded position of the window is somewhere off-screen,
            // reposition it so that it is visible on screen
            // handy for cases when switching between a large desktop monitor and
            // a smaller built-in laptop screen
            NSRect mainScreenFrame = [[NSScreen mainScreen] frame];
            
            // window horizontal position is out of right-side of screen
            if (persistedWindowPosition.x > (mainScreenFrame.size.width) - 30.0) {
                NSPoint currentWindowPosition = [[self directoryModel] windowPosition];
                NSPoint newWindowPosition = NSMakePoint(mainScreenFrame.size.width - safeWindowDimensions.width, currentWindowPosition.y);
                [[self directoryModel] setWindowPosition:newWindowPosition];
            }
            
            // window vertical position is below bottom of screen
            if (persistedWindowPosition.y > (mainScreenFrame.size.height) - 30.0) {
                NSPoint currentWindowPosition = [[self directoryModel] windowPosition];
                NSPoint newWindowPosition = NSMakePoint(currentWindowPosition.x, mainScreenFrame.size.height - safeWindowDimensions.height);
                [[self directoryModel] setWindowPosition:newWindowPosition];
            }
            
            // window horizontal position is out of left-side of screen
            if (persistedWindowPosition.x < 0.0) {
                NSPoint currentWindowPosition = [[self directoryModel] windowPosition];
                NSPoint newWindowPosition = NSMakePoint(30.0, currentWindowPosition.y);
                [[self directoryModel] setWindowPosition:newWindowPosition];
            }
            
            // window vertical position is above top of screen
            if (persistedWindowPosition.y < 0.0) {
                NSPoint currentWindowPosition = [[self directoryModel] windowPosition];
                NSPoint newWindowPosition = NSMakePoint(currentWindowPosition.x, 30.0);
                [[self directoryModel] setWindowPosition:newWindowPosition];
            }
        }
        
        [self setOpenItemState];
        
        NSWindowController *finderWindow = [CFRWindowManager.sharedInstance createWindowForDirectory:[self directoryModel]];
        [finderWindow showWindow:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:event.window.windowController
                                                 selector:@selector(closeOpenedFolder:)
                                                     name:NSWindowWillCloseNotification
                                                   object:finderWindow.window];
    }
}

- (void)normalFolderTitleTextColor
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSMutableDictionary *attributes = [@{
        NSForegroundColorAttributeName: [[CCIApplicationStyles instance] blackColor],
        NSFontAttributeName: self.folderLabel.font,
        NSParagraphStyleAttributeName: paragraphStyle
    } mutableCopy];
    if (self.directoryModel.labelIndex > 0) attributes[NSBackgroundColorAttributeName] = [[CCIApplicationStyles instance] labelColorForIndex:self.directoryModel.labelIndex];
    self.folderLabel.attributedStringValue = [[NSAttributedString alloc] initWithString:self.folderLabel.stringValue
                                                                              attributes:attributes];
}

- (void)setFolderTitleText:(NSString *)title
{
    self.folderLabel.stringValue = CCITruncatedIconTitle(title ?: @"", self.folderLabel.font, self.folderLabel.frame.size.width - 4.0);
    [self normalFolderTitleTextColor];
}

- (void)reverseFolderTitleTextColor
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [[CCIApplicationStyles instance] whiteColor],
        NSBackgroundColorAttributeName: [CCIApplicationStyles instance].appearanceVersion == CCIClassicAppearanceMacOS9 ? [[CCIApplicationStyles instance] darkPurpleColor] : [[CCIApplicationStyles instance] blackColor],
        NSFontAttributeName: self.folderLabel.font,
        NSParagraphStyleAttributeName: paragraphStyle
    };
    self.folderLabel.attributedStringValue = [[NSAttributedString alloc] initWithString:self.folderLabel.stringValue
                                                                              attributes:attributes];
}

- (void)selectItem
{
    [self setFolderSelected:YES];
    [self reverseFolderTitleTextColor];
    [[self iconImage] selectFolder];
    [self setNeedsDisplay:YES];
}

- (void)deselectItem
{
    [self setFolderSelected:NO];
    [self normalFolderTitleTextColor];
    [[self iconImage] unselectFolder];
    [self setNeedsDisplay:YES];
}

- (void)setOpenItemState
{
    [self setFolderOpened:YES];
    [[self iconImage] openFolder];
    [self setNeedsDisplay:YES];
}

- (void)setCloseItemState
{
    [self setFolderOpened:NO];
    [[self iconImage] closeFolder];
    [self setNeedsDisplay:YES];
}

@end
