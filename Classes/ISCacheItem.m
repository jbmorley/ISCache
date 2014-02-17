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

#import <ISUtilities/ISNotifier.h>
#import "ISCacheItem.h"
#import "ISCacheExceptions.h"
#import "ISCache.h"
#import "ISCache+Private.h"

@interface ISCacheItem ()

@property (weak) ISCache *cache;
@property (nonatomic, strong) NSMutableDictionary *fileDict;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) ISNotifier *notifier;

@end

@implementation ISCacheItem

@synthesize state = _state;
@synthesize userInfo = _userInfo;

static int kCacheItemVersion = 1;

static NSString *const kKeyIdentifier = @"identifier";
static NSString *const kKeyContext = @"context";
static NSString *const kKeyPreferences = @"preferences";
static NSString *const kKeyPath = @"path";
static NSString *const kKeyFiles = @"files";
static NSString *const kKeyUid = @"uid";
static NSString *const kKeyVersion = @"version";
static NSString *const kKeyState = @"state";
static NSString *const kKeyTotalBytesRead = @"totalBytesRead";
static NSString *const kKeyTotalBytesExpectedToRead = @"totakBytesExpectedToRead";
static NSString *const kKeyCreated = @"created";
static NSString *const kKeyModified = @"modified";
static NSString *const kKeyUserInfo = @"userInfo";


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
  self = [self init];
  if (self) {
    _notifier = [ISNotifier new];
    _identifier = identifier;
    _context = context;
    _preferences = preferences;
    _uid = uid;
    _path = path;
    _cache = cache;
    _fileDict = [NSMutableDictionary dictionaryWithCapacity:3];
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
  self = [self init];
  if (self) {
    
    _fileDict = [NSMutableDictionary dictionaryWithCapacity:3];
    
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
    NSDictionary *files = dictionary[kKeyFiles];
    if (files) {
      for (NSString *filename in files) {
        ISCacheFile *file =
        [[ISCacheFile alloc] initWithDirectory:_path
                                      filename:filename];
        [_fileDict setObject:file
                      forKey:filename];
      }
    }
    self.state = [dictionary[kKeyState] intValue];
    self.totalBytesRead = [dictionary[kKeyTotalBytesRead] longLongValue];
    self.totalBytesExpectedToRead = [dictionary[kKeyTotalBytesExpectedToRead] longLongValue];
    self.created = dictionary[kKeyCreated];
    self.modified = dictionary[kKeyModified];
    self.userInfo = dictionary[kKeyUserInfo];
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
    
    NSMutableArray *files =
    [NSMutableArray arrayWithCapacity:3];
    for (NSString *filename in self.fileDict) {
      ISCacheFile *file = self.fileDict[filename];
      [files addObject:file.filename];
    }
    [dictionary setObject:files
                   forKey:kKeyFiles];
    
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
    if (self.userInfo != nil) {
      [dictionary setObject:self.userInfo
                     forKey:kKeyUserInfo];
    }
    
    return dictionary;
    
  }
}


- (void)setUserInfo:(NSDictionary *)userInfo
{
  if (_userInfo == userInfo) {
    return;
  }
  _userInfo = userInfo;
  [self.cache itemDidUpdate:self];
  [self _notifyObservers];
}


- (BOOL)isEqual:(id)object
{
  if ([object class] == [self class]) {
    ISCacheItem *otherItem = (ISCacheItem *)object;
    return ([self.uid isEqualToString:otherItem.uid]);
  }
  return [super isEqual:object];
}


- (void)setState:(ISCacheItemState)state
{
  if (_state == state) {
    return;
  }
  _state = state;
  [self.cache itemDidUpdate:self];
  [self _notifyObservers];
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

      // TODO This calculation is wrong.
      CGFloat remaining = (CGFloat)(totalBytesExpectedToRead - totalBytesRead) / (CGFloat)totalBytesExpectedToRead;
      
      return interval * remaining;
      
    }

  }
}


- (void)closeFiles
{
  [self.fileDict enumerateKeysAndObjectsUsingBlock:
   ^(NSString *key, ISCacheFile *file, BOOL *stop) {
     [file close];
   }];
}


- (void)removeFiles
{
  [self.fileDict enumerateKeysAndObjectsUsingBlock:
   ^(NSString *key, ISCacheFile *file, BOOL *stop) {
     [file remove];
  }];
}


- (NSArray *)files
{
  return [self.fileDict allKeys];
}


- (ISCacheFile *)file:(NSString *)name
{
  ISCacheFile *file = [self.fileDict objectForKey:name];
  if (file == nil) {
    file = [[ISCacheFile alloc] initWithDirectory:self.path
                                         filename:name];
    [self.fileDict setObject:file
                      forKey:name];
  }
  return file;
}


- (ISCacheFile *)defaultFile
{
  return [self.fileDict allValues][0];
}


- (void)fetch
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.cache fetchItemForIdentifier:self.identifier
                               context:self.context
                           preferences:self.preferences];
  });
}


- (void)remove
{
  [self.cache removeItems:@[self]];
}


- (void)cancel
{
  [self.cache cancelItems:@[self]];
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


- (void)setModified:(NSDate *)modified
{
  if ([_modified isEqual:modified]) {
    return;
  }
  _modified = modified;
  [self.cache itemDidUpdate:self];
  [self _notifyObservers];
}


- (void)setTotalBytesExpectedToRead:(long long)totalBytesExpectedToRead
{
  if (_totalBytesExpectedToRead ==
      totalBytesExpectedToRead) {
    return;
  }
  _totalBytesExpectedToRead = totalBytesExpectedToRead;
  [self _notifyObservers];
}


- (void)setTotalBytesRead:(long long)totalBytesRead
{
  if (_totalBytesRead == totalBytesRead) {
    return;
  }
  _totalBytesRead = totalBytesRead;
  [self _notifyObservers];
}


- (BOOL)filesExist
{
  BOOL result = YES;
  for (NSString *name in self.fileDict) {
    ISCacheFile *file = [self.fileDict objectForKey:name];
    result &= [file exists];
  }
  return result;
}


- (void)addCacheItemObserver:(id<ISCacheItemObserver>)observer
                     options:(ISCacheItemObserverOptions)options
{
  [self.notifier addObserver:observer];
  if ((options & ISCacheItemObserverOptionsInitial) > 0) {
    [observer cacheItemDidChange:self];
  }
}


- (void)removeCacheItemObserver:(id<ISCacheItemObserver>)observer
{
  [self.notifier removeObserver:observer];
}


- (void)_notifyObservers
{
  [self.notifier notify:@selector(cacheItemDidChange:)
             withObject:self];
}


@end
