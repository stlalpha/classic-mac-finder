//
//  CCIScrollContentView.m
//  Classic Scrolling2
//
//  Created by Ben Szymanski on 11/12/17.
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

#import "CCIScrollContentView.h"
#import "CCIClassicFinderWindowController.h"
#import "CCIFinderIconProtocol.h"

@interface CCIScrollContentView ()

@property (nonatomic) NSPoint selectionAnchor;
@property (nonatomic) NSRect selectionRect;
@property (nonatomic) BOOL selectionInProgress;
@property (nonatomic) BOOL selectionDragged;
@property (nonatomic, copy) NSArray<NSView *> *selectionAtMouseDown;
@property (nonatomic) NSEventModifierFlags selectionModifiers;

@end

@implementation CCIScrollContentView

- (void)mouseDown:(NSEvent *)event
{
    self.selectionAnchor = [self convertPoint:event.locationInWindow fromView:nil];
    self.selectionRect = NSMakeRect(self.selectionAnchor.x, self.selectionAnchor.y, 0.0, 0.0);
    self.selectionInProgress = YES;
    self.selectionDragged = NO;
    self.selectionAtMouseDown = [self.finderWindowController selectedIconViews];
    self.selectionModifiers = event.modifierFlags & (NSEventModifierFlagShift | NSEventModifierFlagCommand);

    BOOL modified = self.selectionModifiers != 0;
    if (!modified) [self.finderWindowController deselectAllItems];
}

- (void)mouseDragged:(NSEvent *)event
{
    if (!self.selectionInProgress) return;
    NSPoint currentPoint = [self convertPoint:event.locationInWindow fromView:nil];
    self.selectionRect = NSMakeRect(MIN(self.selectionAnchor.x, currentPoint.x),
                                    MIN(self.selectionAnchor.y, currentPoint.y),
                                    fabs(currentPoint.x - self.selectionAnchor.x),
                                    fabs(currentPoint.y - self.selectionAnchor.y));
    self.selectionDragged = self.selectionDragged || (fabs(currentPoint.x - self.selectionAnchor.x) > 3.0 || fabs(currentPoint.y - self.selectionAnchor.y) > 3.0);
    if (self.selectionDragged) {
        NSMutableArray<NSView *> *intersectingItems = [NSMutableArray array];
        for (NSView *item in self.subviews) {
            if (![item conformsToProtocol:@protocol(CCIFinderIconProtocol)]) continue;
            if (NSIntersectsRect(self.selectionRect, item.frame)) [intersectingItems addObject:item];
        }
        if ((self.selectionModifiers & NSEventModifierFlagCommand) != 0) {
            NSMutableArray<NSView *> *toggledItems = [self.selectionAtMouseDown mutableCopy];
            for (NSView *item in intersectingItems) {
                NSUInteger index = [toggledItems indexOfObjectIdenticalTo:item];
                if (index == NSNotFound) [toggledItems addObject:item];
                else [toggledItems removeObjectAtIndex:index];
            }
            [self.finderWindowController selectIconViews:toggledItems];
        } else if ((self.selectionModifiers & NSEventModifierFlagShift) != 0) {
            NSMutableOrderedSet<NSView *> *combinedItems = [NSMutableOrderedSet orderedSetWithArray:self.selectionAtMouseDown];
            [combinedItems addObjectsFromArray:intersectingItems];
            [self.finderWindowController selectIconViews:combinedItems.array];
        } else {
            [self.finderWindowController selectIconViews:intersectingItems];
        }
    }
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event
{
    self.selectionInProgress = NO;
    self.selectionDragged = NO;
    self.selectionRect = NSZeroRect;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    if (self.selectionRect.size.width < 2.0 || self.selectionRect.size.height < 2.0) return;

    NSBezierPath *marquee = [NSBezierPath bezierPathWithRect:self.selectionRect];
    CGFloat dashPattern[] = {2.0, 2.0};
    [marquee setLineDash:dashPattern count:2 phase:0.0];
    [NSColor.blackColor setStroke];
    [marquee stroke];
}

//- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
//    
//    NSUInteger iterationCount = 0;
//    for (NSUInteger y = 0; y < self.frame.size.height; y += 30)
//    {
//        if (iterationCount % 2 == 0) {
//            [[NSColor redColor] setFill];
//        } else {
//            [[NSColor whiteColor] setFill];
//        }
//        
//        NSRectFill(NSMakeRect(0, y, self.frame.size.width, (y + 30)));
//        
//        NSString *yPos = [NSString stringWithFormat:@"%ld", y];
//        [yPos drawAtPoint:NSMakePoint(2.0, (y + 2.0)) withAttributes:nil];
//        
//        iterationCount += 1;
//    }
//}

- (BOOL)isFlipped
{
    return YES;
}

@end
