//
//  CFRFloppyDisk.m
//  Classic Finder
//
//  Created by Ben Szymanski on 1/14/18.
//  Copyright © 2018 Ben Szymanski. All rights reserved.
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

#import "CFRFloppyDisk.h"
#import "CFRFileSystemUtils.h"
#import "CFRFileModel.h"
#import "CFRDirectoryModel.h"
#import "CFRAppModel.h"

@implementation CFRFloppyDisk

+ (NSString *)archivePathForModel:(id<CFRFileSystemObject>)model
{
    return [self archivePathForUniqueID:model.uniqueID];
}

+ (NSString *)archivePathForUniqueID:(NSString *)uniqueID
{
    NSString *supportDirectory = [CFRFileSystemUtils applicationSupportDirectory];
    if (supportDirectory == nil) {
        return nil;
    }
    return [supportDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", uniqueID]];
}

+ (id)restoreModelAtPath:(NSString *)archivePath ofClass:(Class)modelClass
{
    if (archivePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:archivePath]) {
        return nil;
    }

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:archivePath options:0 error:&error];
    if (data == nil) {
        NSLog(@"Could not read Finder settings at %@: %@", archivePath, error.localizedDescription);
        return nil;
    }

    id model = [NSKeyedUnarchiver unarchivedObjectOfClass:modelClass fromData:data error:&error];
    if (model == nil) {
        NSLog(@"Could not restore Finder settings at %@: %@", archivePath, error.localizedDescription);
    }
    return model;
}

+ (BOOL)persistModel:(id<CFRFileSystemObject>)model atPath:(NSString *)archivePath
{
    if (archivePath == nil) {
        return NO;
    }

    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model requiringSecureCoding:YES error:&error];
    if (data == nil || ![data writeToFile:archivePath options:NSDataWritingAtomic error:&error]) {
        NSLog(@"Could not save Finder settings at %@: %@", archivePath, error.localizedDescription);
        return NO;
    }
    return YES;
}

+ (void)restoreFileProperties:(CFRFileModel *)fileModel
{
    CFRFileModel *savedModel = [self restoreModelAtPath:[self archivePathForModel:fileModel]
                                                ofClass:CFRFileModel.class];
    fileModel.iconPosition = savedModel ? savedModel.iconPosition : NSMakePoint(-1.0, -1.0);
}

+ (BOOL)restoreDirectoryProperties:(CFRDirectoryModel *)directoryModel
{
    NSString *archivePath = [self archivePathForModel:directoryModel];
    CFRDirectoryModel *savedModel = [self restoreModelAtPath:archivePath ofClass:CFRDirectoryModel.class];
    BOOL restoredLegacyArchive = NO;

    if (savedModel == nil) {
        NSString *legacyArchivePath = [self archivePathForUniqueID:directoryModel.legacyUniqueID];
        if (![legacyArchivePath isEqualToString:archivePath]) {
            savedModel = [self restoreModelAtPath:legacyArchivePath ofClass:CFRDirectoryModel.class];
            restoredLegacyArchive = (savedModel != nil);
        }
    }

    if (savedModel == nil) {
        directoryModel.iconPosition = NSMakePoint(-1.0, -1.0);
        directoryModel.windowDimensions = NSMakeSize(-1.0, -1.0);
        directoryModel.windowPosition = NSMakePoint(-1.0, -1.0);
        return NO;
    }

    directoryModel.iconPosition = savedModel.iconPosition;
    directoryModel.windowDimensions = savedModel.windowDimensions;
    directoryModel.windowPosition = savedModel.windowPosition;
    if (restoredLegacyArchive) {
        [self persistDirectoryProperties:directoryModel];
    }
    return YES;
}

+ (void)restoreAppDirectoryProperties:(CFRAppModel *)appDirectoryModel
{
    CFRAppModel *savedModel = [self restoreModelAtPath:[self archivePathForModel:appDirectoryModel]
                                                ofClass:CFRAppModel.class];
    appDirectoryModel.iconPosition = savedModel ? savedModel.iconPosition : NSMakePoint(-1.0, -1.0);
}

+ (BOOL)persistFileProperties:(CFRFileModel *)fileModel
{
    return [self persistModel:fileModel atPath:[self archivePathForModel:fileModel]];
}

+ (BOOL)persistDirectoryProperties:(CFRDirectoryModel *)directoryModel
{
    return [self persistModel:directoryModel atPath:[self archivePathForModel:directoryModel]];
}

+ (BOOL)persistAppDirectoryProperties:(CFRAppModel *)appDirectoryModel
{
    return [self persistModel:appDirectoryModel atPath:[self archivePathForModel:appDirectoryModel]];
}

@end
