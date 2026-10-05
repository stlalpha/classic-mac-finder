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
#import "CFRFileSystemOperations.h"

@class CCIClassicListRow;

@interface CCIClassicFinderWindow (ListViewActions)
- (void)selectListRow:(CCIClassicListRow *)row;
- (void)openListItem:(id<CFRFileSystemObject>)item;
- (void)sortListByStyle:(NSString *)style;
@end

@interface CCIClassicListRow : NSControl
@property (nonatomic, strong) id<CFRFileSystemObject> item;
@property (nonatomic, weak) CCIClassicFinderWindow *finderWindow;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL compact;
@property (nonatomic) BOOL buttonMode;
@end

static NSString *CCIListDisplayTitle(id<CFRFileSystemObject> item)
{
    NSString *title = item.title ?: @"";
    if ([item.objectPath.pathExtension caseInsensitiveCompare:@"app"] == NSOrderedSame) return title.stringByDeletingPathExtension;
    return title;
}

@implementation CCIClassicListRow
- (BOOL)isFlipped { return YES; }
- (BOOL)isAccessibilityElement { return YES; }
- (NSString *)accessibilityLabel { return CCIListDisplayTitle(self.item); }
- (NSString *)accessibilityRole { return self.buttonMode ? NSAccessibilityButtonRole : NSAccessibilityRowRole; }

- (void)drawSmallIcon
{
    if ([CCIApplicationStyles instance].appearanceVersion == CCIClassicAppearanceMacOS9) {
        NSString *imageName = [self.item isKindOfClass:CFRDirectoryModel.class]
            ? @"MacOS9Folder"
            : ([self.item.objectPath.pathExtension caseInsensitiveCompare:@"app"] == NSOrderedSame ? @"MacOS9Application" : @"MacOS9Document");
        NSImage *image = [NSImage imageNamed:imageName];
        if (image != nil) {
            [image drawInRect:NSMakeRect(1, 1, 20, 20) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:self.isFlipped hints:nil];
            return;
        }
    }
    NSBezierPath *shape = [NSBezierPath bezierPath];
    if ([self.item isKindOfClass:CFRDirectoryModel.class]) {
        [shape moveToPoint:NSMakePoint(2, 5)]; [shape lineToPoint:NSMakePoint(6, 2)];
        [shape lineToPoint:NSMakePoint(10, 2)]; [shape lineToPoint:NSMakePoint(13, 5)];
        [shape lineToPoint:NSMakePoint(19, 5)]; [shape lineToPoint:NSMakePoint(19, 15)];
        [shape lineToPoint:NSMakePoint(2, 15)]; [shape closePath];
        NSColor *folderColor = [CCIApplicationStyles instance].appearanceVersion == CCIClassicAppearanceMacOS9
            ? [NSColor colorWithCalibratedRed:0.78 green:0.80 blue:0.92 alpha:1.0]
            : [NSColor colorWithCalibratedRed:0.82 green:0.82 blue:1.0 alpha:1.0];
        [folderColor setFill];
    } else {
        [shape moveToPoint:NSMakePoint(5, 1)]; [shape lineToPoint:NSMakePoint(15, 1)];
        [shape lineToPoint:NSMakePoint(19, 5)]; [shape lineToPoint:NSMakePoint(19, 15)];
        [shape lineToPoint:NSMakePoint(5, 15)]; [shape closePath];
        [NSColor.whiteColor setFill];
    }
    [shape fill]; [NSColor.blackColor setStroke]; [shape stroke];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.buttonMode) {
        NSRect buttonRect = NSInsetRect(self.bounds, 1, 1);
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[CCIApplicationStyles instance].appearanceVersion == CCIClassicAppearanceMacOS9 ? [NSColor colorWithCalibratedWhite:0.97 alpha:1.0] : NSColor.whiteColor
                                                             endingColor:[CCIApplicationStyles instance].lightGrayColor];
        [gradient drawInRect:buttonRect angle:90];
        [[CCIApplicationStyles instance].darkGrayColor setStroke];
        [NSBezierPath strokeRect:buttonRect];
        [[[CCIApplicationStyles instance] whiteColor] setStroke];
        NSBezierPath *highlight = [NSBezierPath bezierPath];
        [highlight moveToPoint:NSMakePoint(2, NSMaxY(buttonRect) - 1)]; [highlight lineToPoint:NSMakePoint(NSMaxX(buttonRect) - 1, NSMaxY(buttonRect) - 1)]; [highlight stroke];
        [self drawSmallIcon];
        NSRect titleRect = NSMakeRect(27, 0, self.bounds.size.width - 30, self.bounds.size.height);
        NSColor *titleColor = self.selected ? NSColor.whiteColor : NSColor.blackColor;
        if (self.selected) { [[CCIApplicationStyles instance].darkPurpleColor setFill]; NSRectFill(NSMakeRect(25, 1, self.bounds.size.width - 26, self.bounds.size.height - 2)); }
        NSDictionary *titleAttributes = @{NSFontAttributeName: [[CCIApplicationStyles instance] classicBodyFontOfSize:12], NSForegroundColorAttributeName: titleColor};
        [CCIListDisplayTitle(self.item) drawInRect:NSInsetRect(titleRect, 2, 2) withAttributes:titleAttributes];
        return;
    }
    CGFloat nameWidth = self.compact ? self.bounds.size.width : floor(self.bounds.size.width * 0.45);
    NSRect nameRect = NSMakeRect(22, 0, nameWidth - 24, self.bounds.size.height);
    NSDictionary *normal = @{NSFontAttributeName: [[CCIApplicationStyles instance] classicBodyFontOfSize:12], NSForegroundColorAttributeName: NSColor.blackColor};
    if (self.selected) {
        [[[CCIApplicationStyles instance] darkPurpleColor] setFill];
        NSRectFill(nameRect);
    } else if (self.item.labelIndex > 0) {
        [[[CCIApplicationStyles instance] labelColorForIndex:self.item.labelIndex] setFill];
        NSRectFill(nameRect);
    }
    [self drawSmallIcon];
    NSDictionary *titleAttrs = self.selected ? @{NSFontAttributeName: [[CCIApplicationStyles instance] classicBodyFontOfSize:12], NSForegroundColorAttributeName: NSColor.whiteColor} : normal;
    NSString *title = CCIListDisplayTitle(self.item);
    [title drawInRect:NSInsetRect(nameRect, 2, 2) withAttributes:titleAttrs];
    if (self.compact) return;

    CGFloat kindX = self.bounds.size.width * 0.47;
    CGFloat sizeX = self.bounds.size.width * 0.67;
    CGFloat dateX = self.bounds.size.width * 0.82;
    BOOL isApplication = [self.item.objectPath.pathExtension caseInsensitiveCompare:@"app"] == NSOrderedSame;
    NSString *kind = [self.item isKindOfClass:CFRDirectoryModel.class] ? @"Folder" : (isApplication ? @"Application" : (self.item.objectPath.pathExtension.length ? self.item.objectPath.pathExtension.uppercaseString : @"Document"));
    unsigned long long bytes = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.item.objectPath.path error:nil][NSFileSize] unsignedLongLongValue];
    NSString *size = ([self.item isKindOfClass:CFRDirectoryModel.class] || isApplication) ? @"—" : [NSByteCountFormatter stringFromByteCount:(long long)bytes countStyle:NSByteCountFormatterCountStyleFile];
    NSString *date = self.item.lastModified ? [NSDateFormatter localizedStringFromDate:self.item.lastModified dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle] : @"";
    [kind drawAtPoint:NSMakePoint(kindX, 3) withAttributes:normal];
    [size drawAtPoint:NSMakePoint(sizeX, 3) withAttributes:normal];
    [date drawAtPoint:NSMakePoint(dateX, 3) withAttributes:normal];
    [[CCIApplicationStyles instance].midGrayColor setStroke];
    NSBezierPath *separator = [NSBezierPath bezierPath]; [separator moveToPoint:NSMakePoint(0, self.bounds.size.height - 0.5)]; [separator lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height - 0.5)]; [separator stroke];
}

- (void)mouseDown:(NSEvent *)event { [self.finderWindow selectListRow:self]; }
- (void)mouseUp:(NSEvent *)event { if (event.clickCount > 1) [self.finderWindow openListItem:self.item]; }
@end

@interface CCIClassicListHeader : NSView
@property (nonatomic, weak) CCIClassicFinderWindow *finderWindow;
@end

@implementation CCIClassicListHeader
- (BOOL)isFlipped { return YES; }
- (void)drawRect:(NSRect)dirtyRect
{
    [[CCIApplicationStyles instance].midGrayColor setFill]; NSRectFill(self.bounds);
    NSDictionary *attrs = @{NSFontAttributeName: [[CCIApplicationStyles instance] classicBodyFontOfSize:11], NSForegroundColorAttributeName: NSColor.blackColor};
    [@[@"Name", @"Kind", @"Size", @"Date"] enumerateObjectsUsingBlock:^(NSString *title, NSUInteger index, BOOL *stop) {
        CGFloat x = index == 0 ? 5 : (index == 1 ? self.bounds.size.width * 0.47 : (index == 2 ? self.bounds.size.width * 0.67 : self.bounds.size.width * 0.82));
        [title drawAtPoint:NSMakePoint(x, 3) withAttributes:attrs];
    }];
    [[CCIApplicationStyles instance].darkGrayColor setStroke]; NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(0, self.bounds.size.height - 0.5)]; [line lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height - 0.5)]; [line stroke];
}
- (void)mouseDown:(NSEvent *)event
{
    CGFloat x = [self convertPoint:event.locationInWindow fromView:nil].x;
    NSString *style = x < self.bounds.size.width * 0.45 ? @"Name" : (x < self.bounds.size.width * 0.65 ? @"Kind" : (x < self.bounds.size.width * 0.8 ? @"Size" : @"Date"));
    [self.finderWindow sortListByStyle:style];
}
@end

@interface CCIClassicFinderWindow () {
    BOOL windowIsActive;
}

@property (nonatomic, strong) CCITitleBar *titlebar;
@property (nonatomic, strong) CCIClassicFinderDetailBar *detailBar;
@property (nonatomic, strong) CCIScrollView *scrollView;
@property (nonatomic, strong) CCIResizeOverlayOutline *resizeOverlay;
@property (nonatomic, copy) NSString *displayStyle;
@property (nonatomic, weak) CCIClassicListRow *selectedListRow;

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
        _displayStyle = @"Icon";
        
        NSUInteger iconRow = 0;
        NSUInteger iconCol = 0;
        
        for (NSUInteger x = 0; x < self.fileList.count; x += 1) {
            NSObject *fileSystemItem = [self.fileList objectAtIndex:x];
            
            if ([fileSystemItem isMemberOfClass:[CFRDirectoryModel class]])
            {
                CFRDirectoryModel *directoryItem = (CFRDirectoryModel *)fileSystemItem;
                
                CGFloat iconLeftPosition = (10.0 + (iconCol * 80.0));
                CGFloat frameWidthWithBorder = (self.frame.size.width - 70.0);
                if (iconLeftPosition > frameWidthWithBorder) {
                    iconRow += 1;
                    iconCol = 0;
                    iconLeftPosition = (10.0 + (iconCol * 80.0));
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
                [folderIcon setDirectoryModel:directoryItem];
                [folderIcon setFolderTitleText:[directoryItem title]];
                
                [self.scrollView.contentView addSubview:folderIcon];
            } else if ([fileSystemItem isMemberOfClass:[CFRFileModel class]]) {
                CFRFileModel *fileItem = (CFRFileModel *)fileSystemItem;
                
                CGFloat iconLeftPosition = (10.0 + (iconCol * 80.0));
                CGFloat frameWidthWithBorder = (self.frame.size.width - 70.0);
                if (iconLeftPosition > frameWidthWithBorder) {
                    iconRow += 1;
                    iconCol = 0;
                    iconLeftPosition = (10.0 + (iconCol * 80.0));
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
                fileIcon.fileModel = fileItem;
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
        CCIClassicFinderWindowController *windowController = (CCIClassicFinderWindowController *)self.windowController;
        NSString *savedDisplayStyle = windowController.directoryModel.displayStyle ?: @"Icon";
        if (![savedDisplayStyle isEqualToString:@"Icon"]) [self setDisplayStyle:savedDisplayStyle];
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
    CCIClassicFinderWindowController *controller = (CCIClassicFinderWindowController *)self.windowController;
    controller.directoryModel.displayStyle = style;
    [CFRFloppyDisk persistDirectoryProperties:controller.directoryModel];
    self.selectedListRow = nil;
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
            if ([style isEqualToString:@"Label"]) {
                if (a.labelIndex != b.labelIndex) return a.labelIndex < b.labelIndex ? NSOrderedAscending : NSOrderedDescending;
                return [a.title localizedStandardCompare:b.title];
            }
            return [a.title localizedStandardCompare:b.title];
        }];
        BOOL compact = [style isEqualToString:@"Small Icon"];
        BOOL buttons = [style isEqualToString:@"Buttons"];
        if (buttons) {
            CGFloat buttonWidth = 132.0, buttonHeight = 34.0, gapX = 8.0, gapY = 6.0;
            NSUInteger columns = MAX(1, (NSUInteger)floor((content.bounds.size.width - 12.0) / (buttonWidth + gapX)));
            [items enumerateObjectsUsingBlock:^(id<CFRFileSystemObject> item, NSUInteger idx, BOOL *stop) {
                NSUInteger column = idx % columns, rowIndex = idx / columns;
                CCIClassicListRow *button = [[CCIClassicListRow alloc] initWithFrame:NSMakeRect(6.0 + column * (buttonWidth + gapX), 6.0 + rowIndex * (buttonHeight + gapY), buttonWidth, buttonHeight)];
                button.finderWindow = self; button.item = item; button.compact = YES; button.buttonMode = YES;
                [content addSubview:button];
            }];
            NSRect size = content.frame;
            size.size.height = MAX(self.scrollView.frame.size.height, ceil((CGFloat)items.count / columns) * (buttonHeight + gapY) + 12.0);
            [self.scrollView resizeContentView:size];
            return;
        }
        CGFloat headerHeight = compact ? 0.0 : 22.0;
        CGFloat rowHeight = compact ? 24.0 : 22.0;
        if (!compact) {
            CCIClassicListHeader *header = [[CCIClassicListHeader alloc] initWithFrame:NSMakeRect(0, 0, content.bounds.size.width, headerHeight)];
            header.finderWindow = self;
            [content addSubview:header];
        }
        [items enumerateObjectsUsingBlock:^(id<CFRFileSystemObject> item, NSUInteger idx, BOOL *stop) {
            CCIClassicListRow *row = [[CCIClassicListRow alloc] initWithFrame:NSMakeRect(0, headerHeight + 2.0 + idx * rowHeight, content.bounds.size.width, rowHeight)];
            row.finderWindow = self;
            row.item = item;
            row.compact = compact;
            [content addSubview:row];
        }];
        NSRect size = content.frame;
        size.size.height = MAX(self.scrollView.frame.size.height, items.count * rowHeight + headerHeight + 4.0);
        [self.scrollView resizeContentView:size];
        return;
    }

    CGFloat iconSize = 60.0;
    NSArray *items = self.fileList;
    NSUInteger row = 0, col = 0;
    for (id<CFRFileSystemObject> item in items) {
        CGFloat x = 10.0 + col * 80.0;
        if (x > self.frame.size.width - 70.0) { row++; col = 0; x = 10.0; }
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

- (void)selectListRow:(CCIClassicListRow *)row
{
    self.selectedListRow.selected = NO;
    [self.selectedListRow setNeedsDisplay:YES];
    self.selectedListRow = row;
    row.selected = YES;
    [row setNeedsDisplay:YES];
}

- (void)sortListByStyle:(NSString *)style
{
    [self setDisplayStyle:style];
}

- (void)openListItem:(id<CFRFileSystemObject>)item
{
    if ([item isKindOfClass:CFRFileModel.class]) {
        [CFRFileSystemOperations openFileAtURL:item.objectPath];
        return;
    }

    CFRDirectoryModel *directory = (CFRDirectoryModel *)item;
    [CFRFloppyDisk restoreDirectoryProperties:directory];
    NSSize dimensions = directory.windowDimensions;
    if (dimensions.width <= 0.0) dimensions.width = 500.0;
    if (dimensions.height <= 0.0) dimensions.height = 300.0;
    directory.windowDimensions = dimensions;
    if (directory.windowPosition.x < 0.0 || directory.windowPosition.y < 0.0) {
        directory.windowPosition = NSMakePoint(self.frame.origin.x + 30.0, self.frame.origin.y - 30.0);
    }
    [CFRFloppyDisk persistDirectoryProperties:directory];
    CCIClassicFinderWindowController *controller = [[CFRWindowManager sharedInstance] createWindowForDirectory:directory];
    [controller showWindow:self];
}

- (void)moveIconView:(NSView *)iconView toFrame:(NSRect)frame
{
    iconView.frame = frame;
    id<CFRFileSystemObject> model = [iconView isKindOfClass:CCIClassicFolder.class] ? ((CCIClassicFolder *)iconView).directoryModel : ((CCIClassicFile *)iconView).fileModel;
    model.iconPosition = frame.origin;
    if ([model isKindOfClass:CFRDirectoryModel.class]) [CFRFloppyDisk persistDirectoryProperties:(CFRDirectoryModel *)model];
    else if ([model isKindOfClass:CFRFileModel.class]) [CFRFloppyDisk persistFileProperties:(CFRFileModel *)model];
}

- (void)applyLabelIndex:(NSInteger)labelIndex
{
    if (self.selectedListRow != nil) {
        self.selectedListRow.item.labelIndex = labelIndex;
        if ([self.selectedListRow.item isKindOfClass:CFRDirectoryModel.class]) [CFRFloppyDisk persistDirectoryProperties:(CFRDirectoryModel *)self.selectedListRow.item];
        else [CFRFloppyDisk persistFileProperties:(CFRFileModel *)self.selectedListRow.item];
        [self.selectedListRow setNeedsDisplay:YES];
    } else {
        [(CCIClassicFinderWindowController *)self.windowController applyLabelIndex:labelIndex];
    }
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
