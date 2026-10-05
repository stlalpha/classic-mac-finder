//
//  Classic_FinderUITests.m
//  Classic FinderUITests
//
//  Created by Ben Szymanski on 2/18/17.
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

#import <XCTest/XCTest.h>

@interface Classic_FinderUITests : XCTestCase

@property (nonatomic, strong) XCUIApplication *application;

@end

@implementation Classic_FinderUITests

- (void)setUp
{
    [super setUp];
    self.continueAfterFailure = NO;
    self.application = [[XCUIApplication alloc] init];
}

- (void)testLaunchDisplaysRootVolumeSummary
{
    [self.application launch];

    XCUIElement *itemCount = self.application.staticTexts.firstMatch;
    XCTAssertTrue([itemCount waitForExistenceWithTimeout:10.0]);
}

- (void)testViewMenuSwitchesBetweenIconAndListLayouts
{
    [self.application launch];

    XCUIElement *viewMenu = self.application.menuBars.menuBarItems[@"View"];
    XCTAssertTrue([viewMenu waitForExistenceWithTimeout:5.0]);
    [viewMenu click];
    [self.application.menuItems[@"by Name"] click];

    NSPredicate *folderRow = [NSPredicate predicateWithFormat:@"label CONTAINS %@", @"Applications"];
    XCUIElement *folderRowElement = [[self.application descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:folderRow].firstMatch;
    XCTAssertTrue([folderRowElement waitForExistenceWithTimeout:5.0]);

    [viewMenu click];
    [self.application.menuItems[@"by Icon"] click];
    XCTAssertTrue(self.application.staticTexts.firstMatch.exists);
}

- (void)testDoubleClickFolderOpensChildWindowWithZoomRect
{
    [self.application launch];

    XCUIElement *itemCount = self.application.staticTexts.firstMatch;
    XCTAssertTrue([itemCount waitForExistenceWithTimeout:10.0]);
    XCUIElement *usersFolder = self.application.buttons[@"Users"];
    XCTAssertTrue([usersFolder waitForExistenceWithTimeout:10.0]);
    [self.application activate];
    [[usersFolder coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)] doubleTap];

    [NSThread sleepForTimeInterval:0.25];
    XCTAttachment *folderOpenScreenshot = [XCTAttachment attachmentWithScreenshot:self.application.screenshot];
    folderOpenScreenshot.name = @"Folder state immediately after double-click";
    folderOpenScreenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:folderOpenScreenshot];

    NSPredicate *twoWindowsPredicate = [NSPredicate predicateWithFormat:@"count == 2"];
    XCTNSPredicateExpectation *twoWindowsExpectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:twoWindowsPredicate
                                                                                                    object:self.application.windows];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[twoWindowsExpectation] timeout:5.0], XCTWaiterResultCompleted);
    XCUIElement *frontWindow = [self.application.windows elementBoundByIndex:0];
    XCUIElement *parentWindow = [self.application.windows elementBoundByIndex:1];
    XCTAssertGreaterThanOrEqual(frontWindow.frame.size.width, 200.0, @"A child window must not open at the 31-point icon width.");
    XCTAssertLessThan(frontWindow.frame.size.width, parentWindow.frame.size.width, @"The Users window should come in front of the wider root window.");

    XCTAttachment *openedFolderScreenshot = [XCTAttachment attachmentWithScreenshot:self.application.screenshot];
    openedFolderScreenshot.name = @"Users folder opened after ZoomRect";
    openedFolderScreenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:openedFolderScreenshot];

    [[[frontWindow coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)] coordinateWithOffset:CGVectorMake(14.0, 9.0)] click];
    NSPredicate *oneWindowPredicate = [NSPredicate predicateWithFormat:@"count == 1"];
    XCTNSPredicateExpectation *parentWindowExpectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:oneWindowPredicate
                                                                                                     object:self.application.windows];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[parentWindowExpectation] timeout:5.0], XCTWaiterResultCompleted,
                   @"Closing the Users window should finish its ZoomRect and return to the root window.");
}

- (void)testCloseBoxClosesWindowThreeFoldersDeep
{
    [self.application launch];

    XCUIElement *usersFolder = self.application.buttons[@"Users"];
    XCTAssertTrue([usersFolder waitForExistenceWithTimeout:10.0]);
    [[usersFolder coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)] doubleTap];

    XCUIElement *homeFolder = self.application.buttons[@"jm"];
    XCTAssertTrue([homeFolder waitForExistenceWithTimeout:10.0]);
    [[homeFolder coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)] doubleTap];

    NSPredicate *nestedFolderPredicate = [NSPredicate predicateWithFormat:@"label == %@", @"110m_cultural"];
    XCUIElement *nestedFolder = [[self.application descendantsMatchingType:XCUIElementTypeTableRow] matchingPredicate:nestedFolderPredicate].firstMatch;
    XCTAssertTrue([nestedFolder waitForExistenceWithTimeout:10.0]);
    [[nestedFolder coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)] doubleTap];

    NSPredicate *fourWindowsPredicate = [NSPredicate predicateWithFormat:@"count == 4"];
    XCTNSPredicateExpectation *fourWindowsExpectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:fourWindowsPredicate
                                                                                                      object:self.application.windows];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[fourWindowsExpectation] timeout:10.0], XCTWaiterResultCompleted);

    XCUIElement *frontWindow = [self.application.windows elementBoundByIndex:0];
    [[[frontWindow coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)] coordinateWithOffset:CGVectorMake(14.0, 9.0)] click];

    NSPredicate *threeWindowsPredicate = [NSPredicate predicateWithFormat:@"count == 3"];
    XCTNSPredicateExpectation *threeWindowsExpectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:threeWindowsPredicate
                                                                                                       object:self.application.windows];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[threeWindowsExpectation] timeout:5.0], XCTWaiterResultCompleted,
                   @"Clicking the close box should close the deepest folder window.");

    XCUIElement *parentWindow = [self.application.windows elementBoundByIndex:0];
    [[[parentWindow coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)] coordinateWithOffset:CGVectorMake(14.0, 9.0)] click];
    NSPredicate *twoWindowsPredicate = [NSPredicate predicateWithFormat:@"count == 2"];
    XCTNSPredicateExpectation *twoWindowsExpectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:twoWindowsPredicate
                                                                                                      object:self.application.windows];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[twoWindowsExpectation] timeout:5.0], XCTWaiterResultCompleted,
                   @"The parent folder window should also close from its close box.");

    parentWindow = [self.application.windows elementBoundByIndex:0];
    [[[parentWindow coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)] coordinateWithOffset:CGVectorMake(14.0, 9.0)] click];
    NSPredicate *oneWindowPredicate = [NSPredicate predicateWithFormat:@"count == 1"];
    XCTNSPredicateExpectation *oneWindowExpectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:oneWindowPredicate
                                                                                                     object:self.application.windows];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[oneWindowExpectation] timeout:5.0], XCTWaiterResultCompleted,
                   @"The Users window should close and leave the root window open.");
}

@end
