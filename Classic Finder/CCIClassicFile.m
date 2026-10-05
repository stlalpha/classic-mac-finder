//
//  CCIClassicFile.m
//  Classic Finder
//
//  Created by Ben Szymanski on 10/4/17.
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

#import "CCIClassicFile.h"
#import "CCIClassicFileIcon.h"
#import "CFRFileSystemOperations.h"
#import "CCIClassicFinderWindowController.h"
#import "CCIApplicationStyles.h"

static NSString *CCITruncatedFileIconTitle(NSString *title, NSFont *font, CGFloat maxWidth)
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

@interface CCIClassicFile()

@property (nonatomic, copy) NSString *fileTitle;
@property (nonatomic, strong) CCIClassicFileIcon *iconImage;
@property BOOL fileSelected;
@property NSPoint dragStartLocation;
@property NSRect dragStartFrame;

@end

@implementation CCIClassicFile

- (void)setFileModel:(id<CFRFileSystemObject>)fileModel
{
    _fileModel = fileModel;
    self.iconImage.applicationIcon = [fileModel.objectPath.pathExtension caseInsensitiveCompare:@"app"] == NSOrderedSame;
    [self.iconImage setNeedsDisplay:YES];
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self)
    {
        self.fileSelected = NO;
        
        NSRect fileIconFrame = NSMakeRect(18.5, 2.0, 31.0, 31.0);
        self.iconImage = [[CCIClassicFileIcon alloc] initWithFrame:fileIconFrame];
        
        [self addSubview:self.iconImage];
        
        NSRect fileLabelFrame = NSMakeRect(-3.5, 35.0, 75.0, 24.0);
        self.fileLabel = [[NSTextField alloc] initWithFrame:fileLabelFrame];
        self.fileLabel.alignment = NSTextAlignmentCenter;
        self.fileLabel.font = [[CCIApplicationStyles instance] classicBodyFontOfSize:10.0];
        self.fileLabel.bordered = NO;
        self.fileLabel.selectable = NO;
        self.fileLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.fileLabel.usesSingleLineMode = YES;
        self.fileLabel.maximumNumberOfLines = 1;
        self.fileLabel.drawsBackground = NO;

        [self normalFileTitleTextColor];
        
        [self addSubview:self.fileLabel];
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
    self.fileLabel.font = [[CCIApplicationStyles instance] classicBodyFontOfSize:10.0];
    [self setFileTitleText:self.fileModel.title ?: @""];
    if (self.fileSelected) [self reverseFileTitleTextColor];
    else [self normalFileTitleTextColor];
    [self.iconImage setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}

//- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
//
//    // Drawing code here.
//}

- (BOOL)isFlipped
{
    return YES;
}

- (void)mouseDown:(NSEvent *)event
{
    CCIClassicFinderWindowController *wc = event.window.windowController;
    self.dragStartLocation = [self.superview convertPoint:event.locationInWindow fromView:nil];
    self.dragStartFrame = self.frame;
    [wc selectedNewFile:self];
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
        [CFRFileSystemOperations openFileAtURL:self.representedFile];
    }
}

- (void)normalFileTitleTextColor
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSMutableDictionary *attributes = [@{
        NSForegroundColorAttributeName: [[CCIApplicationStyles instance] blackColor],
        NSFontAttributeName: self.fileLabel.font,
        NSParagraphStyleAttributeName: paragraphStyle
    } mutableCopy];
    if ([self.fileModel respondsToSelector:@selector(labelIndex)] && [self.fileModel labelIndex] > 0) attributes[NSBackgroundColorAttributeName] = [[CCIApplicationStyles instance] labelColorForIndex:[self.fileModel labelIndex]];
    self.fileLabel.attributedStringValue = [[NSAttributedString alloc] initWithString:self.fileLabel.stringValue
                                                                            attributes:attributes];
}

- (void)setFileTitleText:(NSString *)title
{
    NSString *displayTitle = title ?: @"";
    if ([self.fileModel.objectPath.pathExtension caseInsensitiveCompare:@"app"] == NSOrderedSame) displayTitle = displayTitle.stringByDeletingPathExtension;
    self.fileLabel.stringValue = CCITruncatedFileIconTitle(displayTitle, self.fileLabel.font, self.fileLabel.frame.size.width - 4.0);
    [self normalFileTitleTextColor];
}

- (void)reverseFileTitleTextColor
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [[CCIApplicationStyles instance] whiteColor],
        NSBackgroundColorAttributeName: [CCIApplicationStyles instance].appearanceVersion == CCIClassicAppearanceMacOS9 ? [[CCIApplicationStyles instance] darkPurpleColor] : [[CCIApplicationStyles instance] blackColor],
        NSFontAttributeName: self.fileLabel.font,
        NSParagraphStyleAttributeName: paragraphStyle
    };
    self.fileLabel.attributedStringValue = [[NSAttributedString alloc] initWithString:self.fileLabel.stringValue
                                                                            attributes:attributes];
}

- (void)selectItem
{
    self.fileSelected = YES;
    [self reverseFileTitleTextColor];
    [self.iconImage selectFile];
    [self setNeedsDisplay:YES];
}

- (void)deselectItem
{
    self.fileSelected = NO;
    [self normalFileTitleTextColor];
    [self.iconImage deselectFile];
    [self setNeedsDisplay:YES];
}


- (void)setOpenItemState
{
    // this method is not used on this icon
}

- (void)setCloseItemState
{
    // this method is not used on this icon
}

@end
