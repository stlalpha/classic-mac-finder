//
//  CCIClassicFinderWindow.m
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

#import "CCIClassicFinderWindow.h"
#import "CCIClassicContentView.h"
#import "CCITitleBar.h"
#import "CCIClassicFinderDetailBar.h"
#import "CCIScrollView.h"
#import "CCIScrollContentView.h"
#import "CCIClassicFolder.h"
#import "CCIClassicFile.h"
#import "CFRWindowManager.h"
#import "CFRDirectoryModel.h"
#import "CFRFileModel.h"
#import "CFRAppModel.h"
#import "CCIClassicFinderWindowController.h"
#import "CCIResizeOverlayOutline.h"
#import "CCIApplicationStyles.h"
#import "CFRFloppyDisk.h"

@interface CCIClassicFinderWindow () {
    BOOL windowIsActive;
}

@property (nonatomic, strong) CCITitleBar *titlebar;
@property (nonatomic, strong) CCIClassicFinderDetailBar *detailBar;
@property (nonatomic, strong) CCIScrollView *scrollView;
@property (nonatomic, strong) CCIResizeOverlayOutline *resizeOverlay;
@property (nonatomic, copy) NSString *displayStyle;

@end

@implementation CCIClassicFinderWindow

- (instancetype)initWithContentRect:(NSRect)contentRect
                          styleMask:(NSWindowStyleMask)style
                            backing:(NSBackingStoreType)bufferingType
                              defer:(BOOL)flag
                    withWindowTitle:(NSString *)windowTitle
                           fileList:(NSArray *)fileList
                      andController:(CCIClassicFinderWindowController *)wc
{
    self = [super initWithContentRect:contentRect
                            styleMask:style
                              backing:bufferingType
                                defer:flag];
    
    if (self)
    {
        windowIsActive = YES;
        [self setWindowTitle:windowTitle];
        [self setFileList:fileList];
        [self setWindowController:wc];
        
        [self setBackgroundColor:[NSColor clearColor]];
        
        self.contentView = [[CCIClassicContentView alloc] initWithFrame:self.frame];
        
        NSRect contentArea = [self.contentView contentArea];
        NSRect titlebarFrame = NSMakeRect(0.0,
                                          0.0,
                                          contentArea.size.width,
                                          19.0);
        
        self.titlebar = [[CCITitleBar alloc] initWithFrame:titlebarFrame];
        self.titlebar.titleText = self.windowTitle;
        self.titlebar.windowIsActive = YES;
        [[self titlebar] setDelegate:self.windowController];
        
        if (self.windowController == nil) {
            NSLog(@"window controller is nil");
        }
        
        [self.contentView addSubview:self.titlebar];
        
        NSRect detailFrame = NSMakeRect(0.0, 19.0, contentArea.size.width, 25.0);
        self.detailBar = [[CCIClassicFinderDetailBar alloc] initWithFrame:detailFrame];
        [self.detailBar setNumberOfFileItemsText:self.fileList.count];
        [self.contentView addSubview:self.detailBar];
        
        
        NSRect scrollViewFrame = NSMakeRect(1.0,
                                            44.0,
                                            self.frame.size.width - 3.0,
                                            self.frame.size.height - 44.0 - 1.0);
        
        self.scrollView = [[CCIScrollView alloc] initWithFrame:scrollViewFrame
                                                 andController:self.windowController];
        [self.contentView addSubview:self.scrollView];
        
        NSUInteger iconRow = 0;
        NSUInteger iconCol = 0;
        
        for (NSUInteger x = 0; x < self.fileList.count; x += 1) {
            NSObject *fileSystemItem = [self.fileList objectAtIndex:x];
            
            if ([fileSystemItem isMemberOfClass:[CFRDirectoryModel class]])
            {
                CFRDirectoryModel *directoryItem = (CFRDirectoryModel *)fileSystemItem;
                
                CGFloat iconLeftPosition = (10.0 + (iconCol * 60.0));
                CGFloat frameWidthWithBorder = (self.frame.size.width - 55.0);
                if (iconLeftPosition > frameWidthWithBorder) {
                    iconRow += 1;
                    iconCol = 0;
                    iconLeftPosition = (10.0 + (iconCol * 60.0));
                }
                
                CGFloat iconTopPosition = 15.0 + (iconRow * 60.0);
                if (directoryItem.iconPosition.x >= 0.0 && directoryItem.iconPosition.y >= 0.0) {
                    iconLeftPosition = directoryItem.iconPosition.x;
                    iconTopPosition = directoryItem.iconPosition.y;
                }
                
                CGRect folderFrame = NSMakeRect(iconLeftPosition,
                                                iconTopPosition,
                                                55.0,
                                                60.0);
                
                CCIClassicFolder *folderIcon = [[CCIClassicFolder alloc] initWithFrame:folderFrame];
                [folderIcon setFolderTitleText:[directoryItem title]];
                [folderIcon setDirectoryModel:directoryItem];
                
                [self.scrollView.contentView addSubview:folderIcon];
            } else if ([fileSystemItem isMemberOfClass:[CFRFileModel class]]) {
                CFRFileModel *fileItem = (CFRFileModel *)fileSystemItem;
                
                CGFloat iconLeftPosition = (10.0 + (iconCol * 60.0));
                CGFloat frameWidthWithBorder = (self.frame.size.width - 55.0);
                if (iconLeftPosition > frameWidthWithBorder) {
                    iconRow += 1;
                    iconCol = 0;
                    iconLeftPosition = (10.0 + (iconCol * 60.0));
                }
                
                CGFloat iconTopPosition = 15.0 + (iconRow * 60.0);
                if (fileItem.iconPosition.x >= 0.0 && fileItem.iconPosition.y >= 0.0) {
                    iconLeftPosition = fileItem.iconPosition.x;
                    iconTopPosition = fileItem.iconPosition.y;
                }
                
                CGRect folderFrame = NSMakeRect(iconLeftPosition,
                                                iconTopPosition,
                                                55.0,
                                                60.0);
                
                CCIClassicFile *fileIcon = [[CCIClassicFile alloc] initWithFrame:folderFrame];
                [fileIcon setFileTitleText:[fileItem title]];
                fileIcon.representedFile = [fileItem objectPath];
                
                [self.scrollView.contentView addSubview:fileIcon];
            }

            iconCol += 1;
        }
        
        NSRect contentViewSize = self.scrollView.contentView.frame;
        CGFloat newContentHeightSize = ((iconRow * 60.0) < contentViewSize.size.height) ? contentViewSize.size.height : (iconRow * 60.0);
        NSRect newContentViewSize = NSMakeRect(contentViewSize.origin.x, contentViewSize.origin.y, contentViewSize.size.width, newContentHeightSize);
        [self.scrollView resizeContentView:newContentViewSize];
        
        [self setInitialFirstResponder:self.scrollView];
    }
    
    return self;
}

- (void)liveResizeToFrame:(NSRect)frameRect
{
    NSRect overlayPositioning = NSMakeRect(0.0,
                                           0.0,
                                           frameRect.size.width,
                                           frameRect.size.height);
    
    if ([self resizeOverlay] == nil) {
        CCIResizeOverlayOutline *resizeOverlay = [[CCIResizeOverlayOutline alloc] initWithFrame:overlayPositioning];
        [self setResizeOverlay:resizeOverlay];
        [self.contentView addSubview:[self resizeOverlay]];
    }
    
    // GUARD DO NOT LET THE WINDOW GET SMALLER THAN IT CURRENTLY IS
    NSRect windowFrame = frameRect;
    
    if (windowFrame.size.width < self.frame.size.width) {
        windowFrame = NSMakeRect(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
    }
    
    if (windowFrame.size.height < self.frame.size.height) {
        windowFrame = NSMakeRect(self.frame.origin.x, self.frame.origin.y, windowFrame.size.width, self.frame.size.height);
    }
    
    [self setFrame:windowFrame
           display:YES
           animate:NO];
    // ---
    
    [[self resizeOverlay] setFrame:overlayPositioning];
}

- (void)finishedResizeToFrame:(NSRect)frameRect
{
    if ([self resizeOverlay] != nil) {
        // remove frame
        [[self resizeOverlay] removeFromSuperview];
        [self setResizeOverlay:nil];
    }
    
    NSRect roundedFrameRect = NSMakeRect(frameRect.origin.x,
                                         frameRect.origin.y,
                                         round(frameRect.size.width),
                                         round(frameRect.size.height));
    
    // Update Title Bar
    [self setFrame:roundedFrameRect
           display:YES
           animate:NO];
    
    // round these otherwise it'll result in subpixel rendering
    // and that looks like crap on non-retina screens.
    //CGFloat newFrameSizeWidthRounded = round(frameRect.size.width);
    //CGFloat newFrameSizeHeightRounded = round(frameRect.size.height);
    
    NSRect titlebarFrame = NSMakeRect(0.0,
                                      0.0,
                                      roundedFrameRect.size.width - 1.0,
                                      19.0);
    [[self titlebar] setFrame:titlebarFrame];
    
    // Update Detail Bar
    NSRect detailFrame = NSMakeRect(0.0,
                                    19.0,
                                    roundedFrameRect.size.width - 1.0,
                                    25.0);
    [[self detailBar] setFrame:detailFrame];
    
    // Update Scroll View
    NSRect scrollViewFrame = NSMakeRect(1.0,
                                        44.0,
                                        roundedFrameRect.size.width - 3.0,
                                        roundedFrameRect.size.height - 44.0 - 2.0);
    [[self scrollView] setFrame:scrollViewFrame];
}

- (void)setDisplayStyle:(NSString *)style
{
    _displayStyle = [style copy];
    CCIScrollContentView *content = self.scrollView.contentView;
    [content.subviews.copy enumerateObjectsUsingBlock:^(NSView *view, NSUInteger idx, BOOL *stop) { [view removeFromSuperview]; }];

    if (![style isEqualToString:@"Icon"]) {
        NSArray *items = [self.fileList sortedArrayUsingComparator:^NSComparisonResult(id<CFRFileSystemObject> a, id<CFRFileSystemObject> b) {
            if ([style isEqualToString:@"Date"]) return [b.lastModified compare:a.lastModified];
            if ([style isEqualToString:@"Size"]) {
                unsigned long long aSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:a.objectPath.path error:nil][NSFileSize] unsignedLongLongValue];
                unsigned long long bSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:b.objectPath.path error:nil][NSFileSize] unsignedLongLongValue];
                return (aSize > bSize) ? NSOrderedAscending : ((aSize < bSize) ? NSOrderedDescending : NSOrderedSame);
            }
            if ([style isEqualToString:@"Kind"]) {
                NSString *aKind = [a isKindOfClass:CFRDirectoryModel.class] ? @"folder" : a.objectPath.pathExtension.lowercaseString;
                NSString *bKind = [b isKindOfClass:CFRDirectoryModel.class] ? @"folder" : b.objectPath.pathExtension.lowercaseString;
                NSComparisonResult kindOrder = [aKind localizedStandardCompare:bKind];
                if (kindOrder != NSOrderedSame) return kindOrder;
            }
            return [a.title localizedStandardCompare:b.title];
        }];
        CGFloat rowHeight = 22.0;
        [items enumerateObjectsUsingBlock:^(id<CFRFileSystemObject> item, NSUInteger idx, BOOL *stop) {
            NSTextField *row = [[NSTextField alloc] initWithFrame:NSMakeRect(8.0, 7.0 + idx * rowHeight, content.bounds.size.width - 16.0, rowHeight)];
            NSString *kind = [item isKindOfClass:CFRDirectoryModel.class] ? @"Folder" : (item.objectPath.pathExtension.length ? item.objectPath.pathExtension.uppercaseString : @"Document");
            NSString *date = item.lastModified ? [NSDateFormatter localizedStringFromDate:item.lastModified dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle] : @"";
            unsigned long long bytes = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.objectPath.path error:nil][NSFileSize] unsignedLongLongValue];
            NSString *sizeText = [item isKindOfClass:CFRDirectoryModel.class] ? @"—" : [NSByteCountFormatter stringFromByteCount:(long long)bytes countStyle:NSByteCountFormatterCountStyleFile];
            row.stringValue = [NSString stringWithFormat:@"%@     %@     %@     %@", item.title ?: @"", kind, sizeText, date];
            row.font = [[CCIApplicationStyles instance] classicBodyFontOfSize:10.0];
            row.textColor = NSColor.blackColor;
            row.bordered = NO; row.editable = NO; row.drawsBackground = NO;
            row.lineBreakMode = NSLineBreakByTruncatingTail;
            [content addSubview:row];
        }];
        NSRect size = content.frame;
        size.size.height = MAX(self.scrollView.frame.size.height, items.count * rowHeight + 14.0);
        [self.scrollView resizeContentView:size];
        return;
    }

    CGFloat iconSize = 60.0;
    NSArray *items = self.fileList;
    NSUInteger row = 0, col = 0;
    for (id<CFRFileSystemObject> item in items) {
        CGFloat x = 10.0 + col * iconSize;
        if (x > self.frame.size.width - 55.0) { row++; col = 0; x = 10.0; }
        NSPoint savedPosition = item.iconPosition;
        NSRect frame = NSMakeRect(savedPosition.x >= 0.0 && savedPosition.y >= 0.0 ? savedPosition.x : x,
                                  savedPosition.x >= 0.0 && savedPosition.y >= 0.0 ? savedPosition.y : 15.0 + row * iconSize,
                                  55.0, 60.0);
        if ([item isKindOfClass:CFRDirectoryModel.class]) {
            CCIClassicFolder *icon = [[CCIClassicFolder alloc] initWithFrame:frame]; icon.directoryModel = (CFRDirectoryModel *)item; [icon setFolderTitleText:item.title]; [content addSubview:icon];
        } else {
            CCIClassicFile *icon = [[CCIClassicFile alloc] initWithFrame:frame]; icon.fileModel = item; icon.representedFile = item.objectPath; [icon setFileTitleText:item.title]; [content addSubview:icon];
        }
        col++;
    }
    NSRect size = content.frame; size.size.height = MAX(self.scrollView.frame.size.height, (row + 1) * iconSize + 15.0); [self.scrollView resizeContentView:size];
}

- (void)moveIconView:(NSView *)iconView toFrame:(NSRect)frame
{
    iconView.frame = frame;
    id<CFRFileSystemObject> model = [iconView isKindOfClass:CCIClassicFolder.class] ? ((CCIClassicFolder *)iconView).directoryModel : ((CCIClassicFile *)iconView).fileModel;
    model.iconPosition = frame.origin;
    if ([model isKindOfClass:CFRDirectoryModel.class]) [CFRFloppyDisk persistDirectoryProperties:(CFRDirectoryModel *)model];
    else if ([model isKindOfClass:CFRFileModel.class]) [CFRFloppyDisk persistFileProperties:(CFRFileModel *)model];
}

- (void)setWindowActive
{
    windowIsActive = YES;
    
    [self.scrollView setWindowIsActive:windowIsActive];
    [self.titlebar setWindowIsActive:windowIsActive];
}

- (void)setWindowInactive
{
    windowIsActive = NO;
    
    [self.scrollView setWindowIsActive:windowIsActive];
    [self.titlebar setWindowIsActive:windowIsActive];
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)event
{
    NSLog(@"key down = %@", event.characters);
}

- (void)keyUp:(NSEvent *)event
{
    NSLog(@"key up = %@", event.characters);
}

@end
