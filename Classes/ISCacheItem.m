/*
 * Copyright (C) 2013-2014 InSeven Limited.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "ISCacheItem.h"
#import "ISCacheExceptions.h"

typedef enum {
  ISCacheItemInfoFileStateClosed,
  ISCacheItemInfoFileStateOpen,
} ISCacheItemInfoFileState;

@interface ISCacheItem ()

@property (strong) NSFileHandle *fileHandle;
@property ISCacheItemInfoFileState fileState;

@end

@implementation ISCacheItem

static int kCacheItemVersion = 1;

static NSString *kKeyItem = @"item";
static NSString *kKeyContext = @"context";
static NSString *kKeyUserInfo = @"userInfo";
static NSString *kKeyPath = @"path";
static NSString *kKeyIdentifier = @"identifier";
static NSString *kKeyVersion = @"version";
static NSString *kKeyState = @"state";
static NSString *kKeyTotalBytesRead = @"totalBytesRead";
static NSString *kKeyTotalBytesExpectedToRead = @"totakBytesExpectedToRead";
static NSString *kKeyCreated = @"created";
static NSString *kKeyModified = @"modified";


// Serialization to and from a dictionary.
// A future implementation should probably take advatnage of
// NSCoding.


+ (id)itemInfoWithDictionary:(NSDictionary *)dictionary
{
  return [[self alloc] initWithDictionary:dictionary];
}


- (id)init
{
  self = [super init];
  if (self) {
    self.created = nil;
    self.modified = nil;
    self.lastError = nil;
    self.totalBytesExpectedToRead = ISCacheItemTotalBytesUnknown;
    self.totalBytesRead = 0;
    self.state = ISCacheItemStateNotFound;
  }
  return self;
}


- (id)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if (self) {
    
    // Check the cache item version.
    int version = [dictionary[kKeyVersion] intValue];
    if (version != kCacheItemVersion) {
      @throw [NSException exceptionWithName:ISCacheExceptionUnsupportedCacheStoreItemVersion
                                     reason:ISCacheExceptionUnsupportedCacheStoreItemVersionReason userInfo:nil];
    }
    
    self.item = dictionary[kKeyItem];
    self.context = dictionary[kKeyContext];
    self.userInfo = dictionary[kKeyUserInfo];
    self.path = dictionary[kKeyPath];
    self.identifier = dictionary[kKeyIdentifier];
    self.state = [dictionary[kKeyState] intValue];
    self.totalBytesRead = [dictionary[kKeyTotalBytesRead] longLongValue];
    self.totalBytesExpectedToRead = [dictionary[kKeyTotalBytesExpectedToRead] longLongValue];
    self.created = dictionary[kKeyCreated];
    self.modified = dictionary[kKeyModified];
  }
  return self;
}


- (NSDictionary *)dictionary
{
  NSMutableDictionary *dictionary =
  [NSMutableDictionary dictionaryWithObjectsAndKeys:
   @(kCacheItemVersion), kKeyVersion,
   self.item, kKeyItem,
   self.context, kKeyContext,
   self.userInfo, kKeyUserInfo,
   self.path, kKeyPath,
   self.identifier, kKeyIdentifier,
   @(self.state), kKeyState,
   @(self.totalBytesRead), kKeyTotalBytesRead,
   @(self.totalBytesExpectedToRead), kKeyTotalBytesExpectedToRead,
   nil];
  
  if (self.created) {
    [dictionary setObject:self.created
                   forKey:kKeyCreated];
  }
  if (self.modified) {
    [dictionary setObject:self.modified
                   forKey:kKeyModified];
  }
  
  return dictionary;
}


- (void)openFile
{
  @synchronized(self) {
    if (self.fileState == ISCacheItemInfoFileStateClosed) {
      
      self.fileHandle
      = [NSFileHandle fileHandleForWritingAtPath:self.path];
      if (self.fileHandle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:self.path
                                                contents:nil
                                              attributes:nil];
        self.fileHandle
        = [NSFileHandle fileHandleForWritingAtPath:self.path];
      }
      
      [self.fileHandle seekToEndOfFile];
      self.fileState = ISCacheItemInfoFileStateOpen;
    }
  }
}


- (void)closeFile
{
  @synchronized(self) {
    if (self.fileState == ISCacheItemInfoFileStateOpen) {
      [self.fileHandle closeFile];
      self.fileState = ISCacheItemInfoFileStateClosed;
    }
  }
}


- (void)deleteFile
{
  @synchronized(self) {
    
    // Close the file.
    [self closeFile];
    
    // Delete the file.
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.path
                            error:&error];
    if (error) {
      // TODO Handle an error in deleting the file.
      // What can we actually do here if the file wasn't correctly
      // deleted?
    }

  }
}


- (void)writeDataToFile:(NSData *)data
{
  @synchronized(self) {
    [self openFile];
    [self.fileHandle writeData:data];
  }
}


- (BOOL)isEqual:(id)object
{
  if ([object class] == [self class]) {
    ISCacheItem *otherItem = (ISCacheItem *)object;
    return ([self.identifier isEqualToString:otherItem.identifier]);
  }
  return [super isEqual:object];
}


@end
