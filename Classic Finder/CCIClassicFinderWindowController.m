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
        [self setWindow:finderWindow];
        
        [finderWindow makeKeyAndOrderFront:self];

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
    }
    
    return self;
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
    NSSize dimensions = directory.windowDimensions;
    if (dimensions.width <= 0.0) dimensions.width = 500.0;
    if (dimensions.height <= 0.0) dimensions.height = 300.0;
    directory.windowDimensions = dimensions;
    if (directory.windowPosition.x < 0.0 || directory.windowPosition.y < 0.0) {
        directory.windowPosition = NSMakePoint(self.window.frame.origin.x + 30.0, self.window.frame.origin.y - 30.0);
    }
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

- (NSView *)iconAtScreenPoint:(NSPoint)screenPoint
{
    for (NSWindow *window in NSApp.orderedWindows) {
        if (![window isKindOfClass:CCIClassicFinderWindow.class] || !NSPointInRect(screenPoint, window.frame)) continue;
        NSPoint windowPoint = [window convertPointFromScreen:screenPoint];
        NSPoint contentPoint = [window.contentView convertPoint:windowPoint fromView:nil];
        NSView *hitView = [window.contentView hitTest:contentPoint];
        while (hitView != nil && ![hitView isKindOfClass:CCIClassicFolder.class] && ![hitView isKindOfClass:CCIClassicFile.class]) hitView = hitView.superview;
        if ([hitView isKindOfClass:CCIClassicFolder.class] || [hitView isKindOfClass:CCIClassicFile.class]) return hitView;
    }
    return nil;
}

- (CCIClassicFolder *)folderAtScreenPoint:(NSPoint)screenPoint
{
    NSView *icon = [self iconAtScreenPoint:screenPoint];
    return [icon isKindOfClass:CCIClassicFolder.class] ? (CCIClassicFolder *)icon : nil;
}

- (void)updateSpringLoadedFolderForDraggedIcon:(NSView *)iconView atScreenPoint:(NSPoint)screenPoint
{
    if (!CFRWindowManager.sharedInstance.springLoadedFoldersEnabled) {
        [self.springHoverTimer invalidate]; self.springHoverTimer = nil; self.springHoverFolder = nil;
        return;
    }
    CCIClassicFolder *folder = [self folderAtScreenPoint:screenPoint];
    if (folder == iconView || folder == self.springHoverFolder) return;
    [self.springHoverTimer invalidate]; self.springHoverTimer = nil;
    self.springHoverFolder = folder;
    if (folder == nil || folder.folderOpened) return;
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
    [self.springHoverTimer invalidate]; self.springHoverTimer = nil; self.springHoverFolder = nil;
    CCIClassicFolder *folder = [self folderAtScreenPoint:screenPoint];
    if (folder == iconView) folder = nil;
    NSView *targetIcon = [self iconAtScreenPoint:screenPoint];
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
