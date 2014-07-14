//
// Copyright (c) 2013-2014 InSeven Limited.
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

#include <tgmath.h>
#import <ISUtilities/ISNotifier.h>
#import "ISCacheItem.h"
#import "ISCacheExceptions.h"
#import "ISCache.h"
#import "ISCachePrivate.h"
#import "ISCacheItemPrivate.h"
#import "NSObject+Serialize.h"

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


+ (id)_itemWithIdentifier:(NSString *)identifier
                  context:(NSString *)context
              preferences:(NSDictionary *)preferences
                      uid:(NSString *)uid
                     root:(NSString *)root
                     path:(NSString *)path
                    cache:(ISCache *)cache
{
  return [[self alloc] _initWithIdentifier:identifier
                                   context:context
                               preferences:preferences
                                       uid:uid
                                      root:root
                                      path:path
                                     cache:cache];
}


+ (id)_itemInfoWithRoot:(NSString *)root
             dictionary:(NSDictionary *)dictionary
                  cache:(ISCache *)cache
{
  return [[self alloc] _initWithRoot:root
                          dictionary:dictionary
                               cache:cache];
}


- (id)init
{
  self = [super init];
  if (self) {
    _notifier = [ISNotifier new];
    _progressNotifier = [ISNotifier new];
    NSString *queueIdentifier = [NSString stringWithFormat:@"%@%p",
                                 @"uk.co.inseven.cache.",
                                 self];
    _queue = dispatch_queue_create([queueIdentifier UTF8String],
                                   DISPATCH_QUEUE_SERIAL);
    _lastProgress = 0.0f;
    _lastProgressDate = [NSDate date];
    [self _resetState];
  }
  return self;
}


- (id)_initWithIdentifier:(NSString *)identifier
                  context:(NSString *)context
              preferences:(NSDictionary *)preferences
                      uid:(NSString *)uid
                     root:(NSString *)root
                     path:(NSString *)path
                    cache:(ISCache *)cache
{
  self = [self init];
  if (self) {
    _identifier = identifier;
    _context = context;
    _preferences = preferences;
    _uid = uid;
    _root = root;
    _path = path;
    _cache = cache;
    _fileDict = [NSMutableDictionary dictionaryWithCapacity:3];
  }
  return self;
}


// Serialization to and from a dictionary.
// A future implementation should probably take advatnage of
// NSCoding.
- (id)_initWithRoot:(NSString *)root
         dictionary:(NSDictionary *)dictionary
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
    
    _root = root;
    _identifier = dictionary[kKeyIdentifier];
    _context = dictionary[kKeyContext];
    _preferences = dictionary[kKeyPreferences];
    _uid = dictionary[kKeyUid];
    _path = dictionary[kKeyPath];
    NSDictionary *files = dictionary[kKeyFiles];
    if (files) {
      for (NSString *filename in files) {
        NSLog(@"Path: %@", self.path);
        NSString *fileDirectory =
        [NSString pathWithComponents:@[self.root, self.path]];
        NSLog(@"Diretory: %@", fileDirectory);
        ISCacheFile *file =
        [[ISCacheFile alloc] initWithDirectory:fileDirectory
                                      filename:filename];
        [_fileDict setObject:file
                      forKey:filename];
      }
    }
    _state = [dictionary[kKeyState] intValue];
    _totalBytesRead = [dictionary[kKeyTotalBytesRead] longLongValue];
    _totalBytesExpectedToRead = [dictionary[kKeyTotalBytesExpectedToRead] longLongValue];
    _created = dictionary[kKeyCreated];
    _modified = dictionary[kKeyModified];
    self.userInfo = dictionary[kKeyUserInfo];
    self.cache = cache;
  }
  return self;
}


- (NSString *)description
{
  // TODO Flesh this out.
  return [self.userInfo description];
}


- (void)setUserInfo:(NSDictionary *)userInfo
{
  if (_userInfo == userInfo) {
    return;
  }
  _userInfo = userInfo;
  
  // Check that we can serialize the user info.
  if (_userInfo) {
    if (![_userInfo canWriteToFile]) {
      @throw [NSException exceptionWithName:ISCacheExceptionInvalidUserInfo
                                     reason:ISCacheExceptionInvalidUserInfoReason userInfo:nil];
    }
  }
  
//  [self _notifyObservers]; // TODO We probably need to notify of this some other way.
  [self _notifyExternalUpdate]; // TODO This is saving and unpleasant.
}


- (BOOL)isEqual:(id)object
{
  if ([object class] == [self class]) {
    ISCacheItem *otherItem = (ISCacheItem *)object;
    return ([self.uid isEqualToString:otherItem.uid]);
  }
  return [super isEqual:object];
}


- (float)progress
{
  @synchronized(self) {
    if (self.state == ISCacheItemStateFound) {
      return 1.0;
    } else if (self.state == ISCacheItemStateInProgress) {
      float totalBytesExpectedToRead = self.totalBytesExpectedToRead;
      float totalBytesRead = self.totalBytesRead;
      if (totalBytesExpectedToRead == ISCacheItemTotalBytesUnknown) {
        return 0.0f;
      } else {
        return totalBytesRead / totalBytesExpectedToRead;
      }
    } else {
      return 0.0f;
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
      
      NSTimeInterval interval =
      [self.modified timeIntervalSinceNow] * -1;
      CGFloat rate = totalBytesRead / interval;
      CGFloat remaining = totalBytesExpectedToRead - totalBytesRead;
      CGFloat timeRemaining = remaining / rate;

      return timeRemaining;
      
    }

  }
}


- (NSArray *)files
{
  return [self.fileDict allKeys];
}


- (ISCacheFile *)file:(NSString *)name
{
  ISCacheFile *file = [self.fileDict objectForKey:name];
  if (file == nil) {
    NSString *fileDirectory =
    [NSString pathWithComponents:@[self.root, self.path]];
    file = [[ISCacheFile alloc] initWithDirectory:fileDirectory
                                         filename:name];
    [self.fileDict setObject:file
                      forKey:name];
  }
  return file;
}


- (ISCacheFile *)file
{
  if (self.fileDict.count == 0) {
    return nil;
  }
  
  // Guard against unexpected behaviour when there are
  // multiple files.
  assert(self.fileDict.count == 1);
  
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
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.cache removeItems:@[self]];
  });
}


- (void)cancel
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.cache cancelItems:@[self]];
  });
}


- (void)setTotalBytesExpectedToRead:(long long)totalBytesExpectedToRead
{
  assert(_state == ISCacheItemStateInProgress);
  [self.cache log:
   @"ISCacheItem setTotalBytesExpectedToRead:%llu",
   totalBytesExpectedToRead];
  if (_totalBytesExpectedToRead ==
      totalBytesExpectedToRead) {
    return;
  }
  _totalBytesExpectedToRead = totalBytesExpectedToRead;
  [self _notifyProgressObservers];
  [self _notifyObservers];
}


- (void)setTotalBytesRead:(long long)totalBytesRead
{
  assert(_state == ISCacheItemStateInProgress);
  [self.cache log:
   @"ISCacheItem setTotalBytesRead:%llu",
   totalBytesRead];
  if (_totalBytesRead == totalBytesRead) {
    return;
  }
  
  // Update the bytes read.
  _totalBytesRead = totalBytesRead;
  
  // Explicitly limit the update frequency.
  NSTimeInterval timeSinceUpdate = [self.lastProgressDate timeIntervalSinceNow] * -1.0;
  if (timeSinceUpdate < 1.0) {
    return;
  }
  
  // Only notify our observers if the progress has changed
  // significantly or the last update was sufficiently long ago.
  // We also ensure we notify when there is no progress or progress
  // is complete as UIs are likely interested in these events.
  CGFloat progress = [self progress];
  CGFloat step = progress > self.lastProgress ? progress - self.lastProgress : self.lastProgress - progress;
  if (step >= 0.05 ||
      progress == 1.0 ||
      progress == 0.0 ||
      timeSinceUpdate >= 1.0) {
    self.lastProgress = progress;
    self.lastProgressDate = [NSDate date];
    [self _notifyProgressObservers];
  }
}


#pragma mark - Observers


- (void)addCacheItemObserver:(id<ISCacheItemObserver>)observer
                     options:(ISCacheItemObserverOptions)options
{
  [self.notifier addObserver:observer];
  if ((options & ISCacheItemObserverOptionsInitial) > 0) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [observer cacheItemDidChange:self];
    });
  }
}


- (void)removeCacheItemObserver:(id<ISCacheItemObserver>)observer
{
  [self.notifier removeObserver:observer];
}


- (void)addCacheItemProgressObserver:(id<ISCacheItemProgressObserver>)observer
{
  [self.progressNotifier addObserver:observer];
}


- (void)removeCacheItemProgressObserver:(id<ISCacheItemProgressObserver>)observer
{
  [self.progressNotifier removeObserver:observer];
}


- (ISCacheTask *)then:(ISCacheBlock)completionBlock
{
  return [[ISCacheTask alloc] initWithCacheItem:self
                                completionBlock:completionBlock
                                    cancelToken:[ISCancelToken new]];
}


- (ISCacheTask *)then:(ISCacheBlock)completionBlock
          cancelToken:(ISCancelToken *)cancelToken
{
  return [[ISCacheTask alloc] initWithCacheItem:self
                                         completionBlock:completionBlock
                                             cancelToken:cancelToken];
}


#pragma mark - Utilities


- (BOOL)_resetState
{
  @synchronized (self) {
    
    [self _removeFiles];
    
    // Check to see if any changes will be made.
    if (_state == ISCacheItemStateNotFound &&
        _totalBytesExpectedToRead == ISCacheItemTotalBytesUnknown &&
        _totalBytesRead == 0 &&
        _lastError == nil &&
        _created == nil &&
        _modified == nil) {
      return NO;
    }
    
    _state = ISCacheItemStateNotFound;
    _totalBytesExpectedToRead = ISCacheItemTotalBytesUnknown;
    _totalBytesRead = 0;
    _lastError = nil;
    _created = nil;
    _modified = nil;
    
    return YES;
    
  }
}


- (BOOL)_filesExist
{
  BOOL result = YES;
  for (NSString *name in self.fileDict) {
    ISCacheFile *file = [self.fileDict objectForKey:name];
    result &= [file exists];
  }
  return result;
}


- (void)_closeFiles
{
  [self.fileDict enumerateKeysAndObjectsUsingBlock:
   ^(NSString *key, ISCacheFile *file, BOOL *stop) {
     [file close];
   }];
}


- (void)_removeFiles
{
  [self.fileDict enumerateKeysAndObjectsUsingBlock:
   ^(NSString *key, ISCacheFile *file, BOOL *stop) {
     [file remove];
   }];
  [self.fileDict removeAllObjects];
}


#pragma mark - Transitions


- (void)_transitionToInProgress
{
  @synchronized (self) {
    assert(_state == ISCacheItemStateNotFound);
    [self _resetState];
    _state = ISCacheItemStateInProgress;
    _modified = [NSDate new];
    [self _notifyObservers];
  }
}


- (void)_transitionToFound
{
  @synchronized (self) {
    assert(_state == ISCacheItemStateInProgress);
    [self _closeFiles];
    
    if (_state == ISCacheItemStateFound &&
        _lastError == nil) {
      return;
    }
    
    _lastError = nil;
    _state = ISCacheItemStateFound;
    [self _notifyObservers];
  }
}


- (void)_transitionToNotFound
{
  @synchronized (self) {
    BOOL itemChanged = [self _resetState];
    if (!itemChanged) {
      return;
    }
    
    [self _notifyObservers];
  }
}


- (void)_transitionToError:(NSError *)error
{
  @synchronized (self) {
    [self _resetState];
    _lastError = error;
    [self _notifyObservers];
  }
}


- (void)_updateModified
{
  @synchronized (self) {
    _modified = [NSDate new];
    [self _notifyObservers];
  }
}


#pragma mark - Notifications


- (void)_notifyExternalUpdate
{
  [self.cache itemDidUpdate:self];
}


- (void)_notifyObservers
{
  // Notification always happens on the main thread.
  if ([self.notifier count] > 0) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.notifier notify:@selector(cacheItemDidChange:)
                 withObject:self];
    });
  }
}


- (void)_notifyProgressObservers
{
  // Notification always happens on the main thread.
  // We only attempt to dispatch the notification if there is at least
  // one progress notifier.
  if ([self.progressNotifier count] > 0) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.progressNotifier notify:@selector(cacheItemDidProgress:)
                         withObject:self];
    });
  }
}


#pragma mark - Serialization


- (NSDictionary *)_dictionary
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


@end
