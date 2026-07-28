//
//  CCIScrollView.m
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

#import "CCIScrollView.h"
#import "CCIScrollContentContainer.h"
#import "CCIScrollContentView.h"
#import "CCIScrollbar.h"
#import "CCIScrollbarArrowButton.h"
#import "CCIWindowGripButton.h"
#import "CCIApplicationStyles.h"
#import "CCIClassicFinderWindowController.h"

@interface CCIScrollView() {
    id delegate;
    BOOL windowIsActive;
    BOOL activateHorizontalScrollbar;
    BOOL activateVerticleScrollbar;
}

@property (nonatomic) NSSize scrollableDistance;
@property (nonatomic) NSPoint currentScrollPosition;

@property (nonatomic, strong) CCIScrollbar *horizontalScrollbar;
@property (nonatomic, strong) CCIScrollbar *verticalScrollbar;
@property (nonatomic, strong) CCIWindowGripButton *gripButton;

- (void)updateScrollingMetrics;
- (void)setScrollPosition:(NSPoint)scrollPosition;

@end

@implementation CCIScrollView

#pragma mark - INITIALIZATION METHODS
- (instancetype)initWithFrame:(NSRect)frameRect
                andController:(CCIClassicFinderWindowController *)wc
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        delegate = wc;
        
        // Create content view container
        // this view is a container for the actual content view
        // we are wrapping the actual content view in this thing
        // to set the visible bounds of the content area. The actual
        // content view can be any super large size, but it needs
        // a parent view to clip that and set the bounds.
        // Without this, the white of the file icon erases/overlaps over
        // the black line at the top of the scroll view. Looks strange. No good!
        NSRect contentViewContainerFrame = NSMakeRect(0.0, 1.0, frameRect.size.width, (frameRect.size.height - 1.0));
         CCIScrollContentContainer *contentViewContainer = [[CCIScrollContentContainer alloc] initWithFrame:contentViewContainerFrame];
        [self setContentViewContainer:contentViewContainer];
        [self addSubview:self.contentViewContainer];
        
        // // Create content view
        NSRect contentViewFrame = NSMakeRect(0.0, 0.0, frameRect.size.width, (frameRect.size.height - 1.0));
        CCIScrollContentView *contentView = [[CCIScrollContentView alloc] initWithFrame:contentViewFrame];
        [self setContentView:contentView];
        //[self addSubview:self.contentView];
        [[self contentViewContainer] addSubview:contentView];
        
        NSPoint currentScrollPosition = NSMakePoint(0.0, 0.0);
        [self setCurrentScrollPosition:currentScrollPosition];
        
        // // Create scrollbar controls
        CCIScrollbar *verticalScrollbar = [CCIScrollbar verticalScrollbarForScrollView:self
                                                                    withMaxContentSize:900.0];
        [self setVerticalScrollbar:verticalScrollbar];
        [self addSubview:verticalScrollbar];
        
        CCIScrollbar *horizontalScrollbar = [CCIScrollbar horizontalScrollbarForScrollView:self
                                                                        withMaxContentSize:300.0];
        [self setHorizontalScrollbar:horizontalScrollbar];
        [self addSubview:horizontalScrollbar];
        
        // // Create Grip button
        NSRect gripButtonFrame = NSMakeRect(self.frame.size.width - 15.0, self.frame.size.height - 15.0, 15.0, 15.0);
        CCIWindowGripButton *gripButton = [[CCIWindowGripButton alloc] initWithFrame:gripButtonFrame];
        [gripButton setDelegate:delegate];
        [self setGripButton:gripButton];
        
        [self addSubview:gripButton];
        
        [self updateScrollingMetrics];
    }
    
    return self;
}

 - (void)setFrame:(NSRect)frame
{
    [super setFrame: frame];
    
    // Update Content View Container Frame
    NSRect contentViewContainerFrame = NSMakeRect(0.0,
                                                  1.0,
                                                  frame.size.width,
                                                  (frame.size.height - 1.0));
    [[self contentViewContainer] setFrame:contentViewContainerFrame];
    
    // Update Content View Frame
    // We will update the minimum width and/or height
    // of this view if it's current minimum w/h are
    // less than the new w/h.

    NSRect contentViewFrame = [[self contentView] frame];
    
    if (contentViewFrame.size.width < frame.size.width) {
        contentViewFrame = NSMakeRect(contentViewFrame.origin.x,
                                      contentViewFrame.origin.y,
                                      frame.size.width,
                                      contentViewFrame.size.height);
    }
    
    if (contentViewFrame.size.height < frame.size.height) {
        contentViewFrame = NSMakeRect(contentViewFrame.origin.x,
                                      contentViewFrame.origin.y,
                                      contentViewFrame.size.width,
                                      (frame.size.height - 1.0));
    }
    
    [[self contentView] setFrame:contentViewFrame];

    // Update scrollbar controls
    NSRect verticalScrollbarFrame = NSMakeRect(frame.size.width - 15.0,
                                               1.0,
                                               15.0,
                                               (frame.size.height - 15.0));
    [[self verticalScrollbar] setFrame:verticalScrollbarFrame];
   
    NSRect horizontalScrollbarFrame = NSMakeRect(0.0,
                                                 frame.size.height - 15.0,
                                                 (frame.size.width - 14.0),
                                                 15.0);
    [[self horizontalScrollbar] setFrame:horizontalScrollbarFrame];
    
    // Update Grip button Frame
    NSRect gripButtonFrame = NSMakeRect(self.frame.size.width - 15.0,
                                        self.frame.size.height - 15.0,
                                        15.0,
                                        15.0);
    [[self gripButton] setFrame:gripButtonFrame];

    [self updateScrollingMetrics];
}

#pragma mark - NON-COMPUTED PROPERTIES

- (id)delegate
{
    return delegate;
}

- (void)setDelegate:(id)newDelegate
{
    delegate = newDelegate;
}

#pragma mark - EVENT METHODS
- (void)performScrollAction:(id)sender
{
    CCIScrollbarArrowButton *clickedBtn = (CCIScrollbarArrowButton *)sender;
    ButtonDirectionality direction = clickedBtn.direction;
    NSPoint newScrollPosition = self.currentScrollPosition;
    
    if (direction == Up) {
        newScrollPosition.y += 50.0;
    } else if (direction == Down) {
        newScrollPosition.y -= 50.0;
    } else if (direction == Left) {
        newScrollPosition.x += 50.0;
    } else if (direction == Right) {
        newScrollPosition.x -= 50.0;
    }

    [self setScrollPosition:newScrollPosition];
}

- (void)resizeContentView:(NSRect)newFrame
{
    [self.contentView setFrameSize:newFrame.size];
    
    [[self verticalScrollbar] updateMaxContentSize:newFrame.size.height];
    [[self horizontalScrollbar] updateMaxContentSize:newFrame.size.width];

    [self updateScrollingMetrics];
}

- (void)updateScrollingMetrics
{
    NSSize contentSize = self.contentView.frame.size;
    NSSize viewportSize = NSMakeSize(NSMinX(self.verticalScrollbar.frame),
                                    NSMinY(self.horizontalScrollbar.frame) - NSMinY(self.contentViewContainer.frame));

    BOOL canScrollHorizontally = contentSize.width > self.frame.size.width;
    BOOL canScrollVertically = contentSize.height > self.frame.size.height;

    CGFloat horizontalDistance = canScrollHorizontally ? MAX(contentSize.width - viewportSize.width, 0.0) : 0.0;
    CGFloat verticalDistance = canScrollVertically ? MAX(contentSize.height - viewportSize.height, 0.0) : 0.0;

    self.scrollableDistance = NSMakeSize(horizontalDistance, verticalDistance);
    activateHorizontalScrollbar = canScrollHorizontally;
    activateVerticleScrollbar = canScrollVertically;

    if (!canScrollHorizontally) {
        [[self horizontalScrollbar] setEnabled:NO];
        [[self horizontalScrollbar] disableScrollbar];
    } else {
        [[self horizontalScrollbar] setEnabled:YES];
        [[self horizontalScrollbar] enableScrollbar];
    }
    
    if (!canScrollVertically) {
        [[self verticalScrollbar] setEnabled:NO];
        [[self verticalScrollbar] disableScrollbar];
    } else {
        [[self verticalScrollbar] setEnabled:YES];
        [[self verticalScrollbar] enableScrollbar];
    }

    [self setScrollPosition:self.currentScrollPosition];
}

- (void)setScrollPosition:(NSPoint)scrollPosition
{
    CGFloat clampedX = MIN(MAX(scrollPosition.x, -self.scrollableDistance.width), 0.0);
    CGFloat clampedY = MIN(MAX(scrollPosition.y, -self.scrollableDistance.height), 0.0);

    self.currentScrollPosition = NSMakePoint(clampedX, clampedY);
    [self.contentView setFrameOrigin:self.currentScrollPosition];

    CGFloat horizontalFraction = self.scrollableDistance.width > 0.0
                               ? (-clampedX / self.scrollableDistance.width)
                               : 0.0;
    CGFloat verticalFraction = self.scrollableDistance.height > 0.0
                             ? (-clampedY / self.scrollableDistance.height)
                             : 0.0;

    [self.horizontalScrollbar setScrollFraction:horizontalFraction];
    [self.verticalScrollbar setScrollFraction:verticalFraction];
}

- (void)mouseUp:(NSEvent *)event
{
    CCIClassicFinderWindowController *wc = event.window.windowController;
    [wc deselectAllItems];
}

#pragma mark - WINDOW STATE METHODS
- (void)setWindowIsActive:(BOOL)pWindowIsActive
{
    windowIsActive = pWindowIsActive;
    
    if (windowIsActive) {
        if (activateHorizontalScrollbar) {
            [[self horizontalScrollbar] enableScrollbar];
        } else {
            [[self horizontalScrollbar] disableScrollbar];
        }
        
        if (activateVerticleScrollbar) {
            [[self verticalScrollbar] enableScrollbar];
        } else {
            [[self verticalScrollbar] disableScrollbar];
        }

        [[self gripButton] enableButton];
    } else {
        [[self verticalScrollbar] disableAndWhiteOutScrollbar];
        [[self horizontalScrollbar] disableAndWhiteOutScrollbar];
        
        [[self gripButton] disableAndWhiteOutButton];
    }
    
    [self setNeedsDisplay:YES];
}

#pragma mark - DRAWING METHODS
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSRect blackBackgroundFrame = NSMakeRect(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    [[[CCIApplicationStyles instance] blackColor] setFill];
    NSRectFill(blackBackgroundFrame);
    
    NSRect backgroundFrame = NSMakeRect(0.0, 1.0, self.frame.size.width, (self.frame.size.height - 1.0));
    
    // Background Color
    [[[CCIApplicationStyles instance] whiteColor] setFill];
    NSRectFill(backgroundFrame);
    
//    NSBezierPath *topBorder = [[NSBezierPath alloc] init];
//    [topBorder moveToPoint:NSMakePoint(0.0, 0.0)];
//    [topBorder lineToPoint:NSMakePoint(self.frame.size.width, 0.0)];
//    
//    [[[CCIApplicationStyles instance] blackColor] setStroke];
//    [topBorder stroke];
}

- (BOOL)isFlipped
{
    return YES;
}

@end
