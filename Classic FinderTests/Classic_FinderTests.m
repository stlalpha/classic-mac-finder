//
//  Classic_FinderTests.m
//  Classic FinderTests
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
#import "../Classic Finder/CFRDirectoryModel.h"
#import "../Classic Finder/CFRFileModel.h"
#import "../Classic Finder/CFRFileSystemOperations.h"
#import "../Classic Finder/NSString+Hashes.h"

@interface Classic_FinderTests : XCTestCase

@property (nonatomic, strong) NSURL *temporaryDirectoryURL;

@end

@implementation Classic_FinderTests

- (void)setUp
{
    [super setUp];
    NSString *directoryName = [NSString stringWithFormat:@"ClassicFinderTests-%@", [[NSUUID UUID] UUIDString]];
    self.temporaryDirectoryURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
                                  URLByAppendingPathComponent:directoryName isDirectory:YES];

    NSError *error = nil;
    BOOL created = [[NSFileManager defaultManager] createDirectoryAtURL:self.temporaryDirectoryURL
                                            withIntermediateDirectories:YES
                                                             attributes:nil
                                                                  error:&error];
    XCTAssertTrue(created, @"Could not create test directory: %@", error);
}

- (void)tearDown
{
    if (self.temporaryDirectoryURL != nil) {
        [[NSFileManager defaultManager] removeItemAtURL:self.temporaryDirectoryURL error:nil];
    }
    [super tearDown];
}

- (void)testDirectoryIDsDistinguishSameNamedFolders
{
    NSURL *firstPath = [self.temporaryDirectoryURL URLByAppendingPathComponent:@"first/Shared" isDirectory:YES];
    NSURL *secondPath = [self.temporaryDirectoryURL URLByAppendingPathComponent:@"second/Shared" isDirectory:YES];
    CFRDirectoryModel *first = [[CFRDirectoryModel alloc] init];
    CFRDirectoryModel *second = [[CFRDirectoryModel alloc] init];

    first.title = @"Shared";
    second.title = @"Shared";
    first.fileSystemNumber = 123;
    second.fileSystemNumber = 123;
    first.objectPath = firstPath;
    second.objectPath = secondPath;

    XCTAssertNotEqualObjects(first.uniqueID, second.uniqueID);
}

- (void)testDirectoryIDsNormalizeEquivalentPaths
{
    NSURL *path = [self.temporaryDirectoryURL URLByAppendingPathComponent:@"first/Shared" isDirectory:YES];
    NSURL *equivalentPath = [self.temporaryDirectoryURL URLByAppendingPathComponent:@"first/../first/Shared"
                                                                        isDirectory:YES];
    CFRDirectoryModel *first = [[CFRDirectoryModel alloc] init];
    CFRDirectoryModel *second = [[CFRDirectoryModel alloc] init];
    first.objectPath = path;
    second.objectPath = equivalentPath;
    first.fileSystemNumber = 123;
    second.fileSystemNumber = 123;

    XCTAssertEqualObjects(first.uniqueID, second.uniqueID);
}

- (void)testLegacyDirectoryIDUsesPreviousNameAndVolumeFormat
{
    CFRDirectoryModel *directory = [[CFRDirectoryModel alloc] init];
    directory.title = @"Shared";
    directory.fileSystemNumber = 123;

    NSString *legacyValue = [NSString stringWithFormat:@"%lu%@", directory.fileSystemNumber, directory.title];
    XCTAssertEqualObjects(directory.legacyUniqueID, [legacyValue sha1]);
}

- (void)testDirectoryListingReturnsErrorInsteadOfEmptyListingForMissingPath
{
    NSURL *missingDirectory = [self.temporaryDirectoryURL URLByAppendingPathComponent:@"missing" isDirectory:YES];
    NSError *error = nil;

    NSArray *listing = [CFRFileSystemOperations getListingForDirectory:missingDirectory error:&error];

    XCTAssertNil(listing);
    XCTAssertNotNil(error);
}

- (void)testDirectoryListingReturnsEmptyArrayForEmptyDirectory
{
    NSError *error = nil;
    NSArray *listing = [CFRFileSystemOperations getListingForDirectory:self.temporaryDirectoryURL error:&error];

    XCTAssertNotNil(listing);
    XCTAssertEqual(listing.count, 0);
    XCTAssertNil(error);
}

- (void)testDirectoryLabelSurvivesSecureArchiveRoundTrip
{
    CFRDirectoryModel *directory = [[CFRDirectoryModel alloc] init];
    directory.objectPath = [self.temporaryDirectoryURL URLByAppendingPathComponent:@"Labeled" isDirectory:YES];
    directory.fileSystemNumber = 456;
    directory.labelIndex = 5;
    directory.displayStyle = @"Name";

    NSError *error = nil;
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:directory requiringSecureCoding:YES error:&error];
    XCTAssertNotNil(archive);
    XCTAssertNil(error);

    CFRDirectoryModel *restored = [NSKeyedUnarchiver unarchivedObjectOfClass:CFRDirectoryModel.class fromData:archive error:&error];
    XCTAssertEqual(restored.labelIndex, 5);
    XCTAssertEqualObjects(restored.displayStyle, @"Name");
    XCTAssertNil(error);
}

- (void)testApplicationBundleIsListedAsAnApplicationFile
{
    NSURL *applicationURL = [self.temporaryDirectoryURL URLByAppendingPathComponent:@"ClassicApp.app" isDirectory:YES];
    NSError *error = nil;
    BOOL created = [[NSFileManager defaultManager] createDirectoryAtURL:applicationURL
                                            withIntermediateDirectories:NO
                                                             attributes:nil
                                                                  error:&error];
    XCTAssertTrue(created, @"Could not create test application bundle: %@", error);

    NSArray *listing = [CFRFileSystemOperations getListingForDirectory:self.temporaryDirectoryURL error:&error];

    XCTAssertNil(error);
    XCTAssertEqual(listing.count, 1);
    XCTAssertTrue([listing.firstObject isKindOfClass:CFRFileModel.class]);
}

@end
