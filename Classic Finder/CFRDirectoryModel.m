//
//  CFRDirectoryModel.m
//  Classic Finder
//
//  Created by Ben Szymanski on 1/11/18.
//  Copyright © 2018 Ben Szymanski All rights reserved.
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

#import "CFRDirectoryModel.h"
#import "NSString+Hashes.h"

@implementation CFRDirectoryModel

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@synthesize title;
@synthesize creationDate;
@synthesize lastModified;
@synthesize objectPath;
@synthesize fileSystemNumber;

@synthesize iconPosition;
@synthesize labelIndex;
@synthesize windowDimensions;
@synthesize windowPosition;
@synthesize displayStyle;

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self setTitle:@""];
        [self setCreationDate:[NSDate date]];
        [self setLastModified:[NSDate date]];
        [self setObjectPath:[NSURL fileURLWithPath:@"/"]];
        [self setFileSystemNumber:0];
        [self setIconPosition:NSMakePoint(-1.0, -1.0)];
        [self setLabelIndex:0];
        [self setWindowDimensions:NSMakeSize(500.0, 300.0)];
        [self setWindowPosition:NSMakePoint(-1.0, -1.0)];
        [self setDisplayStyle:@"Icon"];
    }
    
    return self;
}

- (NSString *)uniqueID
{
    NSString *directoryPath = self.objectPath.URLByStandardizingPath.path ?: self.title;
    NSString *unhashedID = [NSString stringWithFormat:@"%lu:%@", fileSystemNumber, directoryPath];
    NSString *hashedID = [unhashedID sha1];
    
    return hashedID;
}

- (NSString *)legacyUniqueID
{
    NSString *unhashedID = [NSString stringWithFormat:@"%lu%@", fileSystemNumber, title];
    return [unhashedID sha1];
}

- (NSString *)objectType
{
    return @"directory";
}

#pragma mark - NSCODING METHODS

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self) {
        [self setIconPosition:[aDecoder decodePointForKey:@"iconPosition"]];
        [self setLabelIndex:[aDecoder decodeIntegerForKey:@"labelIndex"]];
        [self setWindowDimensions:[aDecoder decodeSizeForKey:@"windowDimensions"]];
        [self setWindowPosition:[aDecoder decodePointForKey:@"windowPosition"]];
        [self setDisplayStyle:[aDecoder decodeObjectOfClass:NSString.class forKey:@"displayStyle"] ?: @"Icon"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.uniqueID forKey:@"uniqueID"];
    [aCoder encodePoint:self.iconPosition forKey:@"iconPosition"];
    [aCoder encodeInteger:self.labelIndex forKey:@"labelIndex"];
    [aCoder encodeSize:self.windowDimensions forKey:@"windowDimensions"];
    [aCoder encodePoint:self.windowPosition forKey:@"windowPosition"];
    [aCoder encodeObject:self.displayStyle forKey:@"displayStyle"];
}

@end
