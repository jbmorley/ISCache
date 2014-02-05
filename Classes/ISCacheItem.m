//
// Copyright (c) 2013 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "ISCacheItem.h"
#import "ISCacheExceptions.h"
#import "ISCache.h"
#import "ISCache+Private.h"

typedef enum {
  ISCacheItemInfoFileStateClosed,
  ISCacheItemInfoFileStateOpen,
} ISCacheItemInfoFileState;

@interface ISCacheItem ()

@property (strong) NSFileHandle *fileHandle;
@property ISCacheItemInfoFileState fileState;
@property (weak) ISCache *cache;

@end

@implementation ISCacheItem

@synthesize state = _state;

static int kCacheItemVersion = 1;

static NSString *kKeyIdentifier = @"identifier";
static NSString *kKeyContext = @"context";
static NSString *kKeyPreferences = @"preferences";
static NSString *kKeyPath = @"path";
static NSString *kKeyUid = @"uid";
static NSString *kKeyVersion = @"version";
static NSString *kKeyState = @"state";
static NSString *kKeyTotalBytesRead = @"totalBytesRead";
static NSString *kKeyTotalBytesExpectedToRead = @"totakBytesExpectedToRead";
static NSString *kKeyCreated = @"created";
static NSString *kKeyModified = @"modified";


+ (id)itemWithIdentifier:(NSString *)identifier
                 context:(NSString *)context
             preferences:(NSDictionary *)preferences
                     uid:(NSString *)uid
                    path:(NSString *)path
                   cache:(ISCache *)cache
{
  return [[self alloc] initWithIdentifier:identifier
                                  context:context
                              preferences:preferences
                                      uid:uid
                                     path:path
                                    cache:cache];
}


- (id)initWithIdentifier:(NSString *)identifier
                 context:(NSString *)context
             preferences:(NSDictionary *)preferences
                     uid:(NSString *)uid
                    path:(NSString *)path
                   cache:(ISCache *)cache
{
  self = [super init];
  if (self) {
    _identifier = identifier;
    _context = context;
    _preferences = preferences;
    _uid = uid;
    _path = path;
    _cache = cache;
  }
  return self;
}


// Serialization to and from a dictionary.
// A future implementation should probably take advatnage of
// NSCoding.


+ (id)itemInfoWithDictionary:(NSDictionary *)dictionary
                       cache:(ISCache *)cache
{
  return [[self alloc] initWithDictionary:dictionary
                                    cache:cache];
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
                   cache:(ISCache *)cache
{
  self = [super init];
  if (self) {
    
    // Check the cache item version.
    int version = [dictionary[kKeyVersion] intValue];
    if (version != kCacheItemVersion) {
      @throw [NSException exceptionWithName:ISCacheExceptionUnsupportedCacheStoreItemVersion
                                     reason:ISCacheExceptionUnsupportedCacheStoreItemVersionReason userInfo:nil];
    }
    
    _identifier = dictionary[kKeyIdentifier];
    _context = dictionary[kKeyContext];
    _preferences = dictionary[kKeyPreferences];
    _uid = dictionary[kKeyUid];
    _path = dictionary[kKeyPath];
    self.state = [dictionary[kKeyState] intValue];
    self.totalBytesRead = [dictionary[kKeyTotalBytesRead] longLongValue];
    self.totalBytesExpectedToRead = [dictionary[kKeyTotalBytesExpectedToRead] longLongValue];
    self.created = dictionary[kKeyCreated];
    self.modified = dictionary[kKeyModified];
    self.cache = cache;
  }
  return self;
}


- (NSDictionary *)dictionary
{
  @synchronized(self) {
    
    NSMutableDictionary *dictionary =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     @(kCacheItemVersion), kKeyVersion,
     self.identifier, kKeyIdentifier,
     self.context, kKeyContext,
     self.path, kKeyPath,
     self.uid, kKeyUid,
     @(self.state), kKeyState,
     @(self.totalBytesRead), kKeyTotalBytesRead,
     @(self.totalBytesExpectedToRead), kKeyTotalBytesExpectedToRead,
     nil];
    
    if (self.preferences != nil) {
      [dictionary setObject:self.preferences
                     forKey:kKeyPreferences];
    }
    
    if (self.created != nil) {
      [dictionary setObject:self.created
                     forKey:kKeyCreated];
    }
    if (self.modified != nil) {
      [dictionary setObject:self.modified
                     forKey:kKeyModified];
    }
    
    return dictionary;
    
  }
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
    return ([self.uid isEqualToString:otherItem.uid]);
  }
  return [super isEqual:object];
}


- (BOOL)automaticallyNotifiesObserversForState
{
  return NO;
}


- (ISCacheItemState)state
{
  @synchronized(self) {
    return _state;
  }
}


- (void)setState:(ISCacheItemState)state
{
  @synchronized(self) {
    if (_state == state) {
      return;
    }
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(state))];
    _state = state;
    [self didChangeValueForKey:NSStringFromSelector(@selector(state))];
  }
}


- (float)progress
{
  @synchronized(self) {
    float totalBytesExpectedToRead = self.totalBytesExpectedToRead;
    float totalBytesRead = self.totalBytesRead;
    if (totalBytesExpectedToRead == ISCacheItemTotalBytesUnknown) {
      return 0.0f;
    } else {
      return totalBytesRead / totalBytesExpectedToRead;
    }
  }
}


+ (NSSet *)keyPathsForValuesAffectingProgress
{
  return [NSSet setWithObjects:
          @"totalBytesExpectedToRead",
          @"totalBytesRead",
          nil];
}


- (NSTimeInterval)timeRemainingEstimate
{
  @synchronized(self) {
    CGFloat totalBytesExpectedToRead = self.totalBytesExpectedToRead;
    CGFloat totalBytesRead = self.totalBytesRead;

    if (totalBytesExpectedToRead == ISCacheItemTotalBytesUnknown || totalBytesExpectedToRead == 0) {
      
      return 0;
      
    } else if (totalBytesExpectedToRead ==
               totalBytesRead) {
      
      return 0;
      
    } else {
      
      NSTimeInterval interval = [self.modified timeIntervalSinceNow] * -1;
      
      CGFloat remaining = (CGFloat)(totalBytesExpectedToRead - totalBytesRead) / (CGFloat)totalBytesExpectedToRead;
      
      return interval * remaining;
      
    }

  }
}


- (void)fetch
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.cache fetchItemForIdentifier:self.identifier
                               context:self.context
                           preferences:self.preferences];
  });
}


- (void)cancel
{
  [self.cache cancelItems:@[self]];
}


- (void)remove
{
  [self.cache removeItems:@[self]];
}


+ (NSSet *)keyPathsForValuesAffectingTimeRemainingEstimate
{
  return [NSSet setWithObjects:
          @"totalBytesExpectedToRead",
          @"totalBytesRead",
          @"modified",
          @"state",
          nil];
}


@end
