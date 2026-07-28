//
//  Classic_FinderTests.m
//  Classic FinderTests
//
//  Created by Ben Szymanski on 2/18/17.
//  Copyright © 2017 Ben Szymanski. All rights reserved.
//
//
// This file is part of Classic Finder.
//
// Classic Finder is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Classic Finder is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Classic Finder.  If not, see <http://www.gnu.org/licenses/>.

#import <XCTest/XCTest.h>
#import "CCIScrollView.h"
#import "CCIScrollbar.h"

@interface Classic_FinderTests : XCTestCase

@end

@implementation Classic_FinderTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testVerticalScrollBoxUsesCompleteAvailableTravel {
    CCIScrollView *scrollView = [[CCIScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 255.0)
                                                       andController:nil];
    CCIScrollbar *scrollbar = [scrollView valueForKey:@"verticalScrollbar"];
    NSView *scrollBox = [scrollbar valueForKey:@"scroller"];
    NSView *topArrow = [scrollbar valueForKey:@"leftOrUpArrow"];
    NSView *bottomArrow = [scrollbar valueForKey:@"downOrRightArrow"];

    [scrollbar setScrollFraction:0.0];
    XCTAssertEqualWithAccuracy(NSMinY(scrollBox.frame), NSMaxY(topArrow.frame), 0.001);

    [scrollbar setScrollFraction:1.0];
    XCTAssertEqualWithAccuracy(NSMaxY(scrollBox.frame), NSMinY(bottomArrow.frame), 0.001);
}

- (void)testContentAndVerticalScrollBoxReachTheirEndpointsTogether {
    CCIScrollView *scrollView = [[CCIScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 255.0)
                                                       andController:nil];
    [scrollView resizeContentView:NSMakeRect(0.0, 0.0, 500.0, 330.0)];

    CCIScrollbar *scrollbar = [scrollView valueForKey:@"verticalScrollbar"];
    NSView *scrollBox = [scrollbar valueForKey:@"scroller"];
    NSView *bottomArrow = [scrollbar valueForKey:@"downOrRightArrow"];
    id downArrow = [scrollbar valueForKey:@"downOrRightArrow"];
    id upArrow = [scrollbar valueForKey:@"leftOrUpArrow"];

    [scrollView performScrollAction:downArrow];
    [scrollView performScrollAction:downArrow];
    NSPoint bottomPosition = [[scrollView valueForKey:@"currentScrollPosition"] pointValue];

    XCTAssertEqualWithAccuracy(NSMaxY(scrollBox.frame), NSMinY(bottomArrow.frame), 0.001);

    [scrollView performScrollAction:downArrow];
    NSPoint positionAfterExtraDownClick = [[scrollView valueForKey:@"currentScrollPosition"] pointValue];
    XCTAssertEqualWithAccuracy(positionAfterExtraDownClick.y, bottomPosition.y, 0.001);

    [scrollView performScrollAction:upArrow];
    [scrollView performScrollAction:upArrow];
    NSPoint topPosition = [[scrollView valueForKey:@"currentScrollPosition"] pointValue];

    XCTAssertEqualWithAccuracy(topPosition.y, 0.0, 0.001);
}

- (void)testHorizontalScrollBoxUsesCompleteAvailableTravel {
    CCIScrollView *scrollView = [[CCIScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 255.0)
                                                       andController:nil];
    CCIScrollbar *scrollbar = [scrollView valueForKey:@"horizontalScrollbar"];
    NSView *scrollBox = [scrollbar valueForKey:@"scroller"];
    NSView *leftArrow = [scrollbar valueForKey:@"leftOrUpArrow"];
    NSView *rightArrow = [scrollbar valueForKey:@"downOrRightArrow"];

    [scrollbar setScrollFraction:0.0];
    XCTAssertEqualWithAccuracy(NSMinX(scrollBox.frame), NSMaxX(leftArrow.frame), 0.001);

    [scrollbar setScrollFraction:1.0];
    XCTAssertEqualWithAccuracy(NSMaxX(scrollBox.frame), NSMinX(rightArrow.frame), 0.001);
}

@end
