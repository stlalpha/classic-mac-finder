//
//  CFRFileSystemOperations.m
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

#import "CFRFileSystemOperations.h"
#import "CFRFileModel.h"
#import "CFRDirectoryModel.h"
#import "CFRAppModel.h"
#import <AppKit/AppKit.h>

@implementation CFRFileSystemOperations

+ (NSArray *)getListingForDirectory:(NSURL *)directory error:(NSError **)error
{
    NSMutableArray *fileList = [[NSMutableArray alloc] initWithCapacity:64];
    NSArray *keys = @[NSURLNameKey, NSURLIsDirectoryKey, NSURLCreationDateKey, NSURLContentModificationDateKey];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtURL:directory
                                            includingPropertiesForKeys:keys
                                                               options:(NSDirectoryEnumerationSkipsPackageDescendants |
                                                                        NSDirectoryEnumerationSkipsHiddenFiles |
                                                                        NSDirectoryEnumerationSkipsSubdirectoryDescendants)
                                                                 error:error];

    if (directoryContents == nil) {
        return nil;
    }

    for (NSURL *directoryItem in directoryContents) {
        NSNumber *isDirectory = nil;
        NSString *title = nil;
        NSDate *createdDate = nil;
        NSDate *lastModifiedDate = nil;
        [directoryItem getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        [directoryItem getResourceValue:&title forKey:NSURLNameKey error:nil];
        [directoryItem getResourceValue:&createdDate forKey:NSURLCreationDateKey error:nil];
        [directoryItem getResourceValue:&lastModifiedDate forKey:NSURLContentModificationDateKey error:nil];

        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:directoryItem.path error:nil];
        unsigned long long fileSystemNumber = [fileAttributes[NSFileSystemNumber] unsignedLongLongValue];

        if (isDirectory.boolValue) {
            CFRDirectoryModel *directoryModel = [[CFRDirectoryModel alloc] init];
            directoryModel.title = title ?: directoryItem.lastPathComponent;
            directoryModel.creationDate = createdDate ?: [NSDate date];
            directoryModel.lastModified = lastModifiedDate ?: [NSDate date];
            directoryModel.objectPath = directoryItem;
            directoryModel.fileSystemNumber = (unsigned long)fileSystemNumber;
            [fileList addObject:directoryModel];
        } else {
            CFRFileModel *fileModel = [[CFRFileModel alloc] init];
            fileModel.title = title ?: directoryItem.lastPathComponent;
            fileModel.creationDate = createdDate ?: [NSDate date];
            fileModel.lastModified = lastModifiedDate ?: [NSDate date];
            fileModel.objectPath = directoryItem;
            fileModel.fileSystemNumber = (unsigned long)fileSystemNumber;
            [fileList addObject:fileModel];
        }
    }

    return fileList;
}

+ (void)openFileAtURL:(NSURL *)fileURL
{
    if (![NSWorkspace.sharedWorkspace openURL:fileURL]) {
        NSLog(@"Could not open %@", fileURL.path);
    }
}

+ (void)createNewFolderInDirectory:(NSURL *)directory named:(NSString *)directoryName
{
    NSURL *newDirectory = [directory URLByAppendingPathComponent:directoryName isDirectory:YES];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:newDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error]) {
        NSLog(@"Could not create folder %@: %@", newDirectory.path, error.localizedDescription);
    }
}

+ (NSString *)copyNameForURL:(NSURL *)url
{
    NSString *extension = url.pathExtension;
    NSString *baseName = extension.length > 0 ? url.URLByDeletingPathExtension.lastPathComponent : url.lastPathComponent;
    NSString *copyName = [baseName stringByAppendingString:@" copy"];
    return extension.length > 0 ? [copyName stringByAppendingPathExtension:extension] : copyName;
}

+ (NSURL *)siblingURLForItem:(NSURL *)item named:(NSString *)name
{
    return [[item URLByDeletingLastPathComponent] URLByAppendingPathComponent:name];
}

+ (void)logOperation:(NSString *)operation URL:(NSURL *)url error:(NSError *)error
{
    NSLog(@"Could not %@ %@: %@", operation, url.path, error.localizedDescription);
}

+ (void)duplicateFile:(NSURL *)file
{
    NSURL *destination = [self siblingURLForItem:file named:[self copyNameForURL:file]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] copyItemAtURL:file toURL:destination error:&error]) {
        [self logOperation:@"duplicate" URL:destination error:error];
    }
}

+ (void)duplicateDirectory:(NSURL *)directory
{
    NSURL *destination = [self siblingURLForItem:directory named:[self copyNameForURL:directory]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] copyItemAtURL:directory toURL:destination error:&error]) {
        [self logOperation:@"duplicate" URL:destination error:error];
    }
}

+ (void)renameFile:(NSURL *)file to:(NSString *)newName
{
    NSString *extension = file.pathExtension;
    NSString *destinationName = (extension.length > 0 && newName.pathExtension.length == 0)
        ? [newName stringByAppendingPathExtension:extension]
        : newName;
    NSURL *destination = [self siblingURLForItem:file named:destinationName];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:file toURL:destination error:&error]) {
        [self logOperation:@"rename" URL:file error:error];
    }
}

+ (void)renameDirectory:(NSURL *)directory to:(NSString *)newName
{
    NSURL *destination = [self siblingURLForItem:directory named:newName];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:directory toURL:destination error:&error]) {
        [self logOperation:@"rename" URL:directory error:error];
    }
}

+ (void)moveItemToTrash:(NSURL *)item
{
    NSURL *trashedItemURL = nil;
    NSError *error = nil;
    if (![[NSFileManager defaultManager] trashItemAtURL:item resultingItemURL:&trashedItemURL error:&error]) {
        [self logOperation:@"move to Trash" URL:item error:error];
    }
}

+ (void)moveFileToTrash:(NSURL *)file
{
    [self moveItemToTrash:file];
}

+ (void)moveDirectoryToTrash:(NSURL *)directory
{
    [self moveItemToTrash:directory];
}

+ (NSURL *)destinationURLForItem:(NSURL *)item atLocation:(NSURL *)location
{
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:location.path isDirectory:&isDirectory] && isDirectory) {
        return [location URLByAppendingPathComponent:item.lastPathComponent];
    }
    return location;
}

+ (void)moveFile:(NSURL *)file toNewLocation:(NSURL *)location
{
    NSURL *destination = [self destinationURLForItem:file atLocation:location];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:file toURL:destination error:&error]) {
        [self logOperation:@"move" URL:file error:error];
    }
}

+ (void)moveDirectory:(NSURL *)directory toNewLocation:(NSURL *)location
{
    NSURL *destination = [self destinationURLForItem:directory atLocation:location];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:directory toURL:destination error:&error]) {
        [self logOperation:@"move" URL:directory error:error];
    }
}

+ (void)printFile:(NSURL *)file
{
    (void)file;
}

+ (void)createSymLinkOfFile:(NSURL *)file
{
    (void)file;
}

+ (void)searchForFilesNamedLike:(NSString *)searchText
{
    (void)searchText;
}

+ (void)emptyTrash
{
}

+ (void)ejectDisk
{
}

@end
