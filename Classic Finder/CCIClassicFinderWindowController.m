//
//  CCIClassicFinderWindowController.m
//  Classic Finder
//
//  Created by Ben Szymanski on 10/5/17.
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

#import "CCIClassicFinderWindowController.h"
#import "CCIClassicFinderWindow.h"
#import "CFRFileSystemOperations.h"
#import "CFRWindowManager.h"
#import "CCIFinderIconProtocol.h"
#import "CCIClassicFile.h"
#import "CCIClassicFolder.h"
#import "CFRFileSystemUtils.h"
#import "CFRDirectoryModel.h"
#import "CFRFileModel.h"
#import "CFRFloppyDisk.h"
#import "CCIClassicContentView.h"

@interface CCIClassicFinderWindowController ()

@property (nonatomic, copy) NSString *windowDirectoryName;
@property (nonatomic, copy) NSArray *fileList;
@property (nonatomic, strong) NSMutableArray *selectedFiles;
@property (nonatomic, strong) NSTimer *springHoverTimer;
@property (nonatomic, weak) CCIClassicFolder *springHoverFolder;

- (NSView *)iconAtScreenPoint:(NSPoint)screenPoint ignoringIcon:(NSView *)ignoredIcon;
- (NSView *)iconInView:(NSView *)view atPoint:(NSPoint)point ignoringIcon:(NSView *)ignoredIcon;
- (CCIClassicFolder *)folderAtScreenPoint:(NSPoint)screenPoint ignoringIcon:(NSView *)ignoredIcon;

@end

@implementation CCIClassicFinderWindowController

- (instancetype)initForDirectory:(CFRDirectoryModel *)directoryModel
{
    self = [super init];
    
    if (self) {
        NSString *directoryName = [CFRFileSystemUtils determineDirectoryNameForURL:directoryModel.objectPath];
        
        self.directoryModel = directoryModel;
        self.windowDirectoryName = directoryName;
        NSError *listingError = nil;
        self.fileList = [CFRFileSystemOperations getListingForDirectory:self.directoryModel.objectPath
                                                                  error:&listingError];
        self.selectedFiles = [[NSMutableArray alloc] initWithCapacity:50];
        
        NSUInteger windowStyleMask = NSWindowStyleMaskBorderless;
        NSRect initalContentRect = NSMakeRect(self.directoryModel.windowPosition.x,
                                              self.directoryModel.windowPosition.y,
                                              self.directoryModel.windowDimensions.width,
                                              self.directoryModel.windowDimensions.height);
        
        // https://stackoverflow.com/a/33229421/5096725
        CCIClassicFinderWindow *finderWindow = [[CCIClassicFinderWindow alloc] initWithContentRect:initalContentRect
                                                                                         styleMask:windowStyleMask
                                                                                           backing:NSBackingStoreBuffered
                                                                                             defer:YES
                                                                                   withWindowTitle:self.windowDirectoryName
                                                                                          fileList:self.fileList
                                                                                     andController:self];

        [finderWindow setDelegate:[CFRWindowManager sharedInstance]];
        [finderWindow setWindowController:self];
        [finderWindow setMinSize:NSMakeSize(200.0, 120.0)];
        [self setWindow:finderWindow];
        
        if (listingError != nil) {
            [[NSAlert alertWithError:listingError] beginSheetModalForWindow:finderWindow completionHandler:nil];
        }
        
        NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
        
        [dc addObserver:self
               selector:@selector(windowDidResignMain:)
                   name:NSWindowDidResignMainNotification
                 object:finderWindow];
        
        [dc addObserver:self
               selector:@selector(windowDidBecomeMain:)
                   name:NSWindowDidBecomeMainNotification
                 object:finderWindow];

        // Register before showing the window: makeKeyAndOrderFront can post the
        // activation notifications synchronously.
        [dc addObserver:self
               selector:@selector(windowDidBecomeKey:)
                   name:NSWindowDidBecomeKeyNotification
                 object:finderWindow];
        [dc addObserver:self
               selector:@selector(windowDidResignKey:)
                   name:NSWindowDidResignKeyNotification
                 object:finderWindow];

        [finderWindow setWindowInactive];
        [finderWindow makeKeyAndOrderFront:self];
        if (finderWindow.isKeyWindow) [finderWindow setWindowActive];
    }
    
    return self;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [(CCIClassicFinderWindow *)self.window setWindowActive];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [(CCIClassicFinderWindow *)self.window setWindowInactive];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    CCIClassicFinderWindow *finderWindow = (CCIClassicFinderWindow *)self.window;
    [finderWindow setWindowActive];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    CCIClassicFinderWindow *finderWindow = (CCIClassicFinderWindow *)self.window;
    [finderWindow setWindowInactive];
}

- (void)closeOpenedFolder:(NSNotification *)notification
{
    CCIClassicFinderWindow *closingWindow = (CCIClassicFinderWindow *)[notification object];
    CCIClassicFinderWindowController *closingWindowController = closingWindow.windowController;
    
    for (CCIClassicFolder *folder in self.selectedFiles) {
        if (folder.directoryModel.objectPath == closingWindowController.directoryModel.objectPath) {
            [folder setCloseItemState];
            //NSLog(@"closing folder... %@", closingWindowController.representedDirectory);
        }
    }
}

- (void)selectedNewFile:(CCIClassicFile *)file
{
    for (CCIClassicFile *file in self.selectedFiles) {
        [file deselectItem];
    }
    
    [self.selectedFiles removeAllObjects];
    
    [file selectItem];
    [self.selectedFiles addObject:file];
}

- (void)selectedNewFolder:(CCIClassicFolder *)folder
{
    for (CCIClassicFolder *folder in self.selectedFiles) {
        [folder deselectItem];
    }
    
    [self.selectedFiles removeAllObjects];
    
    [folder selectItem];
    [self.selectedFiles addObject:folder];
}

- (void)deselectAllItems
{
    NSMutableArray *selectedFiles = [self selectedFiles];
    
    for (CCIClassicFile *file in selectedFiles) {
        [file deselectItem];
    }
    
    [self.selectedFiles removeAllObjects];
}

- (void)refreshSelectionAppearance
{
    for (id item in self.selectedFiles) {
        if ([item respondsToSelector:@selector(selectItem)]) [item selectItem];
    }
    [(CCIClassicFinderWindow *)self.window refreshListSelectionAppearance];
}

- (void)moveIconView:(NSView *)iconView toFrame:(NSRect)frame
{
    [(CCIClassicFinderWindow *)self.window moveIconView:iconView toFrame:frame];
}

- (NSRect)screenIconRectForView:(NSView *)view
{
    NSRect localRect = view.bounds;
    if ([view isKindOfClass:CCIClassicFolder.class]) localRect = NSMakeRect(14.5, 2.0, 31.0, 25.0);
    else if ([view isKindOfClass:CCIClassicFile.class]) localRect = NSMakeRect(18.5, 2.0, 31.0, 31.0);
    else if ([view isKindOfClass:NSControl.class]) localRect = NSMakeRect(1.0, 1.0, 20.0, 20.0);
    return [view.window convertRectToScreen:[view convertRect:localRect toView:nil]];
}

- (void)openFolder:(CFRDirectoryModel *)directory fromIconView:(NSView *)iconView springLoaded:(BOOL)springLoaded
{
    [CFRFloppyDisk restoreDirectoryProperties:directory];
    NSRect initialFrame = [CFRWindowManager.sharedInstance initialFrameForDirectory:directory relativeToWindow:self.window];
    directory.windowPosition = initialFrame.origin;
    directory.windowDimensions = initialFrame.size;
    [CFRFloppyDisk persistDirectoryProperties:directory];

    if ([iconView conformsToProtocol:@protocol(CCIFinderIconProtocol)]) {
        [(id<CCIFinderIconProtocol>)iconView setOpenItemState];
    }
    NSUInteger windowCount = CFRWindowManager.sharedInstance.numberOfOpenWindows;
    CCIClassicFinderWindowController *controller = [CFRWindowManager.sharedInstance createWindowForDirectory:directory];
    [controller showWindow:self];
    if (windowCount < CFRWindowManager.sharedInstance.numberOfOpenWindows) {
        NSRect iconScreenRect = [self screenIconRectForView:iconView];
        [(CCIClassicFinderWindow *)controller.window animateOpeningFromScreenRect:iconScreenRect];
    }
    if (springLoaded && windowCount < CFRWindowManager.sharedInstance.numberOfOpenWindows) {
        controller.springLoadedWindow = YES;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeOpenedFolder:)
                                                 name:NSWindowWillCloseNotification
                                               object:controller.window];
}

- (void)persistSpatialState
{
    if (self.window == nil || self.springLoadedWindow) return;
    self.directoryModel.windowPosition = self.window.frame.origin;
    self.directoryModel.windowDimensions = self.window.frame.size;
    [CFRFloppyDisk persistDirectoryProperties:self.directoryModel];
}

- (NSView *)iconAtScreenPoint:(NSPoint)screenPoint
                         ignoringIcon:(NSView *)ignoredIcon
{
    for (NSWindow *window in NSApp.orderedWindows) {
        if (![window isKindOfClass:CCIClassicFinderWindow.class] || !NSPointInRect(screenPoint, window.frame)) continue;
        NSPoint windowPoint = [window convertPointFromScreen:screenPoint];
        NSPoint contentPoint = [window.contentView convertPoint:windowPoint fromView:nil];
        NSView *hitView = [self iconInView:window.contentView atPoint:contentPoint ignoringIcon:ignoredIcon];
        if (hitView != nil) return hitView;
    }
    return nil;
}

- (NSView *)iconInView:(NSView *)view atPoint:(NSPoint)point ignoringIcon:(NSView *)ignoredIcon
{
    for (NSView *subview in view.subviews.reverseObjectEnumerator) {
        if (subview == ignoredIcon || subview.isHiddenOrHasHiddenAncestor) continue;
        NSPoint pointInSubview = [subview convertPoint:point fromView:view];
        if (!NSPointInRect(pointInSubview, subview.bounds)) continue;
        if ([subview isKindOfClass:CCIClassicFolder.class] || [subview isKindOfClass:CCIClassicFile.class]) return subview;
        NSView *icon = [self iconInView:subview atPoint:pointInSubview ignoringIcon:ignoredIcon];
        if (icon != nil) return icon;
    }
    return nil;
}

- (CCIClassicFolder *)folderAtScreenPoint:(NSPoint)screenPoint ignoringIcon:(NSView *)ignoredIcon
{
    NSView *icon = [self iconAtScreenPoint:screenPoint ignoringIcon:ignoredIcon];
    return [icon isKindOfClass:CCIClassicFolder.class] ? (CCIClassicFolder *)icon : nil;
}

- (void)updateSpringLoadedFolderForDraggedIcon:(NSView *)iconView atScreenPoint:(NSPoint)screenPoint
{
    CCIClassicFolder *folder = [self folderAtScreenPoint:screenPoint ignoringIcon:iconView];
    if (folder == self.springHoverFolder) return;
    [self.springHoverTimer invalidate]; self.springHoverTimer = nil;
    [self.springHoverFolder setDropTargetHighlighted:NO];
    self.springHoverFolder = folder;
    [folder setDropTargetHighlighted:YES];
    if (!CFRWindowManager.sharedInstance.springLoadedFoldersEnabled || folder == nil || folder.folderOpened) return;
    self.springHoverTimer = [NSTimer timerWithTimeInterval:CFRWindowManager.sharedInstance.springLoadedFolderDelay
                                                    target:self
                                                  selector:@selector(springHoverDelayElapsed:)
                                                  userInfo:nil
                                                   repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.springHoverTimer forMode:NSRunLoopCommonModes];
}

- (void)springHoverDelayElapsed:(NSTimer *)timer
{
    CCIClassicFolder *folder = self.springHoverFolder;
    if (!CFRWindowManager.sharedInstance.springLoadedFoldersEnabled || folder == nil || folder.window == nil) return;
    if (![NSApp.orderedWindows containsObject:folder.window]) return;
    [((CCIClassicFinderWindowController *)folder.window.windowController) openFolder:folder.directoryModel
                                                                         fromIconView:folder
                                                                          springLoaded:YES];
}

- (void)refreshDirectoryListing
{
    NSError *error = nil;
    self.fileList = [CFRFileSystemOperations getListingForDirectory:self.directoryModel.objectPath error:&error];
    if (error != nil || self.fileList == nil) return;
    CCIClassicFinderWindow *window = (CCIClassicFinderWindow *)self.window;
    window.fileList = self.fileList;
    [window setDisplayStyle:window.displayStyle];
}

- (void)finishIconDrag:(NSView *)iconView atScreenPoint:(NSPoint)screenPoint
{
    [self.springHoverTimer invalidate]; self.springHoverTimer = nil;
    [self.springHoverFolder setDropTargetHighlighted:NO]; self.springHoverFolder = nil;
    CCIClassicFolder *folder = [self folderAtScreenPoint:screenPoint ignoringIcon:iconView];
    if (folder == iconView) folder = nil;
    NSView *targetIcon = [self iconAtScreenPoint:screenPoint ignoringIcon:iconView];
    NSURL *destinationURL = folder.directoryModel.objectPath;
    CCIClassicFinderWindowController *destinationController = (CCIClassicFinderWindowController *)folder.window.windowController;
    if (folder.folderOpened) {
        for (NSWindow *window in NSApp.orderedWindows) {
            if (![window isKindOfClass:CCIClassicFinderWindow.class]) continue;
            CCIClassicFinderWindowController *candidate = (CCIClassicFinderWindowController *)window.windowController;
            if ([candidate.directoryModel.objectPath isEqual:destinationURL]) {
                destinationController = candidate;
                break;
            }
        }
    }
    if (folder == nil && (targetIcon == nil || targetIcon == iconView)) {
        for (NSWindow *window in NSApp.orderedWindows) {
            if ([window isKindOfClass:CCIClassicFinderWindow.class] && NSPointInRect(screenPoint, window.frame)) {
                destinationController = (CCIClassicFinderWindowController *)window.windowController;
                destinationURL = destinationController.directoryModel.objectPath;
                break;
            }
        }
    }

    id<CFRFileSystemObject> item = [iconView isKindOfClass:CCIClassicFolder.class]
        ? ((CCIClassicFolder *)iconView).directoryModel : ((CCIClassicFile *)iconView).fileModel;
    NSURL *sourceParent = item.objectPath.URLByDeletingLastPathComponent;
    BOOL destinationIsInsideDraggedDirectory = NO;
    if ([item isKindOfClass:CFRDirectoryModel.class] && destinationURL != nil) {
        NSString *sourcePath = item.objectPath.URLByStandardizingPath.path;
        NSString *destinationPath = destinationURL.URLByStandardizingPath.path;
        NSString *sourcePrefix = [sourcePath stringByAppendingString:@"/"];
        destinationIsInsideDraggedDirectory = [destinationPath isEqualToString:sourcePath] || [destinationPath hasPrefix:sourcePrefix];
    }
    BOOL movedItem = destinationURL != nil && ![destinationURL isEqual:sourceParent] && !destinationIsInsideDraggedDirectory;
    if (movedItem) {
        if ([item isKindOfClass:CFRDirectoryModel.class]) [CFRFileSystemOperations moveDirectory:item.objectPath toNewLocation:destinationURL];
        else [CFRFileSystemOperations moveFile:item.objectPath toNewLocation:destinationURL];
        [self refreshDirectoryListing];
        if (destinationController != nil && destinationController != self) [destinationController refreshDirectoryListing];
    }

    for (NSWindow *window in NSApp.windows.copy) {
        if (![window isKindOfClass:CCIClassicFinderWindow.class]) continue;
        CCIClassicFinderWindowController *springWindow = (CCIClassicFinderWindowController *)window.windowController;
        if (springWindow.springLoadedWindow && springWindow != destinationController) [springWindow.window close];
    }
}

- (void)applyLabelIndex:(NSInteger)labelIndex
{
    for (NSView *view in self.selectedFiles) {
        if ([view isKindOfClass:CCIClassicFolder.class]) {
            CCIClassicFolder *folder = (CCIClassicFolder *)view;
            folder.directoryModel.labelIndex = labelIndex;
            [CFRFloppyDisk persistDirectoryProperties:folder.directoryModel];
            [folder setFolderTitleText:folder.folderLabel.stringValue];
            [folder selectItem];
        } else if ([view isKindOfClass:CCIClassicFile.class]) {
            CCIClassicFile *file = (CCIClassicFile *)view;
            file.fileModel.labelIndex = labelIndex;
            [CFRFloppyDisk persistFileProperties:(CFRFileModel *)file.fileModel];
            [file setFileTitleText:file.fileLabel.stringValue];
            [file selectItem];
        }
    }
}

#pragma mark - TITLEBAR DELEGATE METHODS

- (void)titlebarDidFinishDetectingWindowPositionChange:(CCITitleBar *)sender
{
    NSPoint currentPosition = self.window.frame.origin;
    
    [[self directoryModel] setWindowPosition:currentPosition];
    [CFRFloppyDisk persistDirectoryProperties:[self directoryModel]];
}

#pragma mark - WINDOW GRIP BUTTON DELEGATE METHODS

- (void)gripButtonDidFinishDraggingToCoordinates:(NSPoint)pointDraggedTo
{
    CGFloat newWidth = pointDraggedTo.x - self.window.frame.origin.x;
    CGFloat newHeight = (self.window.frame.origin.y + self.window.frame.size.height) - pointDraggedTo.y;
    
    // this because the mac's coordinate system starts in the lower left
    // we need to reposition the origin coordinate on the y axis
    // by determining the offset between the current y coord and the new
    // y coord
    CGFloat yOriginOffset = self.window.frame.origin.y - (self.window.frame.origin.y - pointDraggedTo.y);
    
    NSRect newWindowFrame = NSMakeRect(self.window.frame.origin.x, yOriginOffset, newWidth, newHeight);
    
    CCIClassicFinderWindow *wcWindow = (CCIClassicFinderWindow *)[self window];
    [wcWindow finishedResizeToFrame:newWindowFrame];
    
    [[self directoryModel] setWindowDimensions:NSMakeSize(newWidth, newHeight)];
    
    
    
    NSPoint currentPosition = self.window.frame.origin;
    [[self directoryModel] setWindowPosition:currentPosition];
    
    
    
    
    [CFRFloppyDisk persistDirectoryProperties:[self directoryModel]];
    
    
    
    CCIClassicContentView *contentView = (CCIClassicContentView *)self.window.contentView;
    [contentView setWindowIsResizing:NO];
    [contentView setNeedsDisplay:YES];
}

- (void)gripButtonIsDraggingToCoordinates:(NSPoint)pointDraggedTo
{
    CCIClassicContentView *contentView = (CCIClassicContentView *)self.window.contentView;
    [contentView setWindowIsResizing:YES];
    [contentView setNeedsDisplay:YES];
    
    
    
    CGFloat newWidth = pointDraggedTo.x - self.window.frame.origin.x;
    CGFloat newHeight = (self.window.frame.origin.y + self.window.frame.size.height) - pointDraggedTo.y;
    
    // this because the mac's coordinate system starts in the lower left
    // we need to reposition the origin coordinate on the y axis
    // by determining the offset between the current y coord and the new
    // y coord
    CGFloat yOriginOffset = self.window.frame.origin.y - (self.window.frame.origin.y - pointDraggedTo.y);
    
    NSRect newWindowFrame = NSMakeRect(self.window.frame.origin.x, yOriginOffset, fabs(newWidth), newHeight);
    
    CCIClassicFinderWindow *wcWindow = (CCIClassicFinderWindow *)[self window];
    [wcWindow liveResizeToFrame:newWindowFrame];
}

@end
