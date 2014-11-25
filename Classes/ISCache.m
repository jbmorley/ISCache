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

#import "ISCache.h"
#import <ISUtilities/ISUtilities.h>
#import <ISUtilities/UIKit+ISUtilities.h>
#import "ISCacheSimpleHandlerFactory.h"
#import "ISCacheStore.h"
#import "NSString+Hashes.h"
#import "ISCachePrivate.h"
#import "ISCacheItemPrivate.h"

// Contexts.
NSString *const ISCacheURLContext = @"URL";
NSString *const ISCacheImageContext = @"Image";

// Errors.
NSString *const ISCacheErrorDomain = @"ISCacheErrorDomain";

@interface ISCache ()

@property (nonatomic, readonly, strong) NSMutableDictionary *factories;
@property (nonatomic, readonly, strong) NSMutableDictionary *active;
@property (nonatomic, readonly, strong) NSString *documentsPath;
@property (nonatomic, readonly, strong) NSString *identifier;
@property (nonatomic, readonly, strong) NSString *path;
@property (nonatomic, readonly, strong) ISCacheStore *store;
@property (nonatomic, readonly, strong) FMDatabase *db;
@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

@property (nonatomic, readwrite, assign) UIBackgroundTaskIdentifier backgroundTask;

@end

#define ASSERT_ON_MAIN_THREAD assert([NSThread isMainThread])

@implementation ISCache

+ (instancetype)defaultCache
{
  static dispatch_once_t onceToken;
  static ISCache *sharedCache;
  dispatch_once(&onceToken, ^{
    sharedCache = [self cacheWithIdentifier:@"uk.co.inseven.cache.store"];
  });
  return sharedCache;
}


+ (instancetype)cacheWithIdentifier:(NSString *)identifier
{
  return [[self alloc] initWithIdentifier:identifier];
}


- (instancetype)initWithIdentifier:(NSString *)identifier
{
  self = [super init];
  if (self) {
    _debug = NO;
    _identifier = identifier;
    _factories = [NSMutableDictionary dictionary];
    _active = [NSMutableDictionary dictionary];
    
    // Create the application support directory for the cache.
    NSString *applicationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                                        NSUserDomainMask,
                                                                        YES) objectAtIndex:0];
    applicationSupport = [applicationSupport stringByAppendingPathComponent:@"Cache"];
    [self createDirectoryAtPath:applicationSupport];
    
    // Generate our unique paths.
    _documentsPath = [applicationSupport stringByAppendingPathComponent:self.identifier];
    _path = [self.documentsPath stringByAppendingPathExtension:@".sqlite"];
    
    // Create our unique paths if necessary.
    [self createDirectoryAtPath:self.documentsPath];
    
    // Create the database.
    _db = [FMDatabase databaseWithPath:self.path];
    if (![_db open]) {
      ISAssertUnreached(@"Unable to read cache database.");
    }
    
    // TODO The uid shoudl be unique?
    if (![_db executeUpdate:
          @"CREATE TABLE IF NOT EXISTS items ("
          @"    id                   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"
          @"    identifier           TEXT NOT NULL,"
          @"    context              TEXT NOT NULL,"
          @"    path                 TEXT NOT NULL,"
          @"    uid                  TEXT NOT NULL,"
          @"    state                INTEGER NOT NULL,"
          @"    bytesRead            INTEGER NOT NULL,"
          @"    bytesExpectedToRead  INTEGER NOT NULL,"
          @"    filename             TEXT NOT NULL DEFAULT '',"
          @"    preferences          TEXT NOT NULL DEFAULT '',"
          @"    userInfo             TEXT NOT NULL DEFAULT ''"
          @");"
          ]) {
      ISAssertUnreached(@"Unable to create cache database.");
    }
    
    // Load all the items from the cache.
    _store = [ISCacheStore new];
    FMResultSet *s = [_db executeQuery:@"SELECT * FROM items"];
    int count = 0;
    while ([s next]) {
      ISCacheItem *item =
      [[ISCacheItem alloc] _initWithResultSet:s
                                         root:self.documentsPath
                                        cache:self];
      item.fmdb = _db;
      [self.store addItem:item];
      count++;
    }
    
    // Create the cache directory if it doesn't exist.
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
      [self createDirectoryAtPath:self.path];
    }
    
    // Register for application notifications.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification object:nil];
    
    // Create the worker queue as this is used by the factory registration.
    NSString *identifier = [NSString stringWithFormat:@"uk.co.inseven.ISCache.worker.%p", self];
    _workerQueue = dispatch_queue_create([identifier UTF8String], DISPATCH_QUEUE_SERIAL);
    
    // Create and register the default factories.
    
    // HTTP Handler
    ISCacheSimpleHandlerFactory *httpFactory = [ISCacheSimpleHandlerFactory factoryWithClass:[ISCacheHTTPHandler class]];
    [self registerFactory:httpFactory
               forContext:ISCacheURLContext];
    
    // Scaling HTTP Handler
    ISCacheScalingHandlerFactory *scalingHttpfactory = [ISCacheScalingHandlerFactory new];
    [self registerFactory:scalingHttpfactory
               forContext:ISCacheImageContext];

  }
  return self;
}


- (BOOL)createDirectoryAtPath:(NSString *)path
{
  BOOL isDirectory = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
    NSError *error;
    [fileManager createDirectoryAtPath:path
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    if (error) {
      return NO;
    }
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:path]];
    return YES;
  }
  return YES;
}


- (void)dealloc
{
  ASSERT_ON_MAIN_THREAD;
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter removeObserver:self];
  dispatch_sync(self.workerQueue, ^{
    [self.db close];
  });
}


- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  assert([fileManager fileExistsAtPath:[URL path]]);
  NSError *error = nil;
  BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES]
                                forKey:NSURLIsExcludedFromBackupKey
                                 error:&error];
  if(!success){
    [self log:@"Error excluding %@ from backup %@", [URL lastPathComponent], error];
  }
  return success;
}


-(void)log:(NSString *)message, ...
{
  if (self.debug) {
    va_list args;
    va_start(args, message);
    NSLogv(message, args);
    va_end(args);
  }
}


- (void)registerFactory:(id<ISCacheHandlerFactory>)factory
             forContext:(NSString *)context
{
  dispatch_async(self.workerQueue, ^{
  
    // Check that there isn't an existing handler for that context.
    if ([self.factories objectForKey:context] != nil) {
      @throw [NSException exceptionWithName:ISCacheExceptionExistingFactoryForContext
                                     reason:ISCacheExceptionFactoryAlreadyRegisteredReason
                                   userInfo:nil];
    }
    
    // Register the handler.
    [self.factories setObject:factory
                       forKey:context];

  });
}


- (void)unregisterFactoryForContext:(NSString *)context
{
  dispatch_async(self.workerQueue, ^{

    [self.factories removeObjectForKey:context];
    
  });
}

- (ISCacheItem *)itemForIdentifier:(NSString *)identifier
                           context:(NSString *)context
{
  NSParameterAssert(identifier);
  NSParameterAssert(context);

  __block ISCacheItem *cacheItem = nil;
  
  dispatch_sync(self.workerQueue, ^{
    
    
    NSString *uid = [ISCache uidForIdentifier:identifier
                                      context:context];
    
    // Return a pre-existing cache item.
    cacheItem = [self.store item:uid];
    if (cacheItem) {
      return;
    }
    
    // Create a new info for the file.
    NSString *path = [self.documentsPath stringByAppendingPathComponent:uid];
    
    // If there isn't an active cache entry and something exists
    // on the file system, it represents a partial download and
    // should be cleaned up.
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path
                          isDirectory:&isDirectory]) {
      NSError *error;
      [fileManager removeItemAtPath:path
                              error:&error];
      if (error != nil) {
        @throw [NSException exceptionWithName:ISCacheExceptionUnableToCreateItemDirectory
                                       reason:ISCacheExceptionUnableToCreateItemDirectoryReason
                                     userInfo:nil];
      }
    }
    
    // Create the cache item.
    cacheItem = [[ISCacheItem alloc] _initWithIdentifier:identifier
                                                 context:context
                                                     uid:uid
                                                    root:self.documentsPath
                                                    path:uid
                                                   cache:self];
    [self.store addItem:cacheItem];
    
    cacheItem.fmdb = self.db;
    [cacheItem save];

    
  });
  
  return cacheItem;
}


- (ISCacheItem *)itemForUid:(NSString *)uid
{
  __block ISCacheItem *cacheItem = nil;
  dispatch_sync(self.workerQueue, ^{
    cacheItem = [self.store item:uid];
  });
  return cacheItem;
}


- (void)fetchItem:(ISCacheItem *)cacheItem
{
  dispatch_async(self.workerQueue, ^{
    
    // Download the cache item if necessary.
    if (cacheItem.state == ISCacheItemStateNotFound) {
      
      // If the item doesn't exist and isn't in progress, fetch it.
      id<ISCacheHandler> handler = [self handlerForContext:cacheItem.context];
      [cacheItem _transitionToInProgress];
      [self.active setObject:handler
                      forKey:cacheItem.uid];
      // Notify the delegates and begin the fetch operation.
      [handler fetchItem:cacheItem
                 updater:self];
      
    }
  });
}


- (void)removeItem:(ISCacheItem *)cacheItem
{
  dispatch_async(self.workerQueue, ^{

    if (cacheItem.state == ISCacheItemStateFound) {
      
      // Reset the cache item state.
      [cacheItem _transitionToNotFound];
      [cacheItem save];
      
    } else if (cacheItem.state == ISCacheItemStateInProgress) {
      
      // If the item is in progress, then cancel the progress.
      id<ISCacheHandler> handler = [self.active objectForKey:cacheItem.uid];
      [handler cancel];
      
    }
    
  });
}


- (void)cancelItem:(ISCacheItem *)cacheItem
{
  dispatch_async(self.workerQueue, ^{

    // Only attmept to cancel the item if it is in progress.
    if (cacheItem.state == ISCacheItemStateInProgress ||
        cacheItem.state == ISCacheItemStateNotFound) {
      
      // TODO Is it correct to be cancelling tasks which are 'not found'?
      
      [self log:@"cancelItem:%@ -> item not found or in progress", cacheItem.uid];
      
      // Handlers are responsible for finalizing the cache item upon cancellation.
      id<ISCacheHandler> handler = [self.active objectForKey:cacheItem.uid];
      [handler cancel];
      
    } else {
      
      [self log:@"cancelItem:%@ -> item already complete, ignoring", cacheItem.uid];
      
    }
    
  });
}


// Return a subset of the items matching the filter.
- (NSArray *)items:(id<ISCacheFilter>)filter
{
  __block NSArray *items = nil;
  dispatch_sync(self.workerQueue, ^{
    items = [self.store items:filter];
  });
  return items;
}


- (void)purge
{
  dispatch_sync(self.workerQueue, ^{
    
    // Close the database.
    [self.db close];
    
    // Delete the files.
    NSError *error;
    BOOL result = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    result &= [fileManager removeItemAtPath:self.path
                                      error:&error];
    ISAssert(error == nil, @"Failed to delete cache database with error %@", error);
    result &= [fileManager removeItemAtPath:self.documentsPath
                                      error:&error];
    ISAssert(error == nil, @"Failed to delete cache documents with error %@", error);

  });
}


#pragma mark - Utility methods


// Check there is a handler factory registered for the context.
// Throws an exception if no handler factory can be found.
- (id<ISCacheHandler>)handlerForContext:(NSString *)context
{
  // TODO Assert this is only ever called internally.
  
  id<ISCacheHandlerFactory> factory = [self.factories objectForKey:context];
  if (factory == nil) {
    @throw [NSException exceptionWithName:ISCacheExceptionMissingFactoryForContext
                                   reason:ISCacheExceptionMissingFactoryForContextReason
                                 userInfo:nil];
  }
  return [factory handlerForContext:context];
}


- (void)cleanupForItem:(ISCacheItem *)item
{
  // TODO Assert this is on the correct thread and only called internally.
  
  // Dispatch the finalize to the handler.
  // We do this asynchronously to make it possible for
  // clients to maintain a list of handlers and iteratively
  // perform an operation on those handlers and also act
  // upon the finalize (e.g. removing from a the list) without
  // encountering mutation during enumeration issues.
  id<ISCacheHandler> handler = self.active[item.uid];
  dispatch_async(dispatch_get_main_queue(), ^{
    [handler finalize];
  });
  
  [self.active removeObjectForKey:item.uid];
  [self endBackgroundTask];
}


- (BOOL)activeHandlersSupportBackgroundFetch
{
  __block BOOL supportsBackground = NO;
  [self.active enumerateKeysAndObjectsUsingBlock:
   ^(NSString *uid, id<ISCacheHandler> handler, BOOL *stop) {
     if ([handler respondsToSelector:@selector(supportsBackgroundFetch)] && [handler supportsBackgroundFetch]) {
       supportsBackground = YES;
       *stop = YES;
     }
   }];
  return supportsBackground;
}


- (void)beginBackgroundTask
{
  if ([self activeHandlersSupportBackgroundFetch]) {
    self.backgroundTask =
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
      NSLog(@"Background task expired.");
    }];
    NSLog(@"Background task started.");
  };
}


- (void)endBackgroundTask
{
  if (self.backgroundTask != 0) {
    if (![self activeHandlersSupportBackgroundFetch]) {
      [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
      self.backgroundTask = 0;
      NSLog(@"Background task complete.");
    }
  }
}


#pragma mark - Observer methods

+ (NSString *)uidForIdentifier:(NSString *)item
                       context:(NSString *)context
{
    return [[NSString stringWithFormat:@"%@:%@", context, item] md5];
}


- (void)itemDidFinish:(ISCacheItem *)item
{
  [self log:@"itemDidFinish:%@", item.uid];
  [item _transitionToFound];
  [item save];
  [self cleanupForItem:item];
}


- (void)itemDidCancel:(ISCacheItem *)item
{
  [self log:@"itemDidCancel:%@", item.uid];
  NSError *error =
  [NSError errorWithDomain:ISCacheErrorDomain
                      code:ISCacheErrorCancelled
                  userInfo:nil];
  [item _transitionToError:error];
  [self cleanupForItem:item];
}


- (void)item:(ISCacheItem *)item
didFailWithError:(NSError *)error
{
  [self log:@"item:%@ didFailWithError: %@", item.uid, error];
  [item _transitionToError:error];
  [item save];
  [self cleanupForItem:item];
}


#pragma mark - NSNotificationCenter


- (void)applicationWillResignActive:(NSNotification *)notification
{
  // TODO Is this called by the completion handler or do we
  // need to defer the completion through an observer?
  [self log:@"applicationWillResignActive:"];
  [self beginBackgroundTask];
}


@end
