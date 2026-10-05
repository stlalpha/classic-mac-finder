//
//  CCIClassicFinderWindowController.h
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

#import <Cocoa/Cocoa.h>
#import "CCIClassicTitlebarDelegate.h"
#import "CCIWindowGripButtonDelegate.h"

@class CCIClassicFile;
@class CCIClassicFolder;
@class CFRDirectoryModel;

@interface CCIClassicFinderWindowController : NSWindowController <CCIClassicTitlebarDelegate, CCIWindowGripButtonDelegate>

@property (nonatomic, strong) CFRDirectoryModel *directoryModel;
@property (nonatomic) BOOL springLoadedWindow;

- (instancetype)initForDirectory:(CFRDirectoryModel *)directoryModel;

- (void)closeOpenedFolder:(NSNotification *)notification;

- (void)selectedNewFile:(CCIClassicFile *)file;
- (void)selectedNewFolder:(CCIClassicFolder *)folder;
- (void)deselectAllItems;
- (void)refreshSelectionAppearance;
- (void)moveIconView:(NSView *)iconView toFrame:(NSRect)frame;
- (void)updateSpringLoadedFolderForDraggedIcon:(NSView *)iconView atScreenPoint:(NSPoint)screenPoint;
- (void)finishIconDrag:(NSView *)iconView atScreenPoint:(NSPoint)screenPoint;
- (void)openFolder:(CFRDirectoryModel *)directory fromIconView:(NSView *)iconView springLoaded:(BOOL)springLoaded;
- (void)persistSpatialState;
- (void)refreshDirectoryListing;
- (void)applyLabelIndex:(NSInteger)labelIndex;


@end
