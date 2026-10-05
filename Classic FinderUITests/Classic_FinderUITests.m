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

@end
