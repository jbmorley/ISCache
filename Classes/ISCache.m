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
#import "ISNotifier.h"
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

@implementation ISCache

static ISCache *sCache;


+ (id)defaultCache
{
  @synchronized (self) {
    if (sCache == nil) {
      sCache = [[self alloc] initWithIdentifier:@"uk.co.inseven.cache.store"];
    }
    return sCache;
  }
}


- (id)initWithIdentifier:(NSString *)identifier
{
  self = [super init];
  if (self) {
    self.debug = NO;
    self.identifier = identifier;
    self.notifier = [ISNotifier new];
    self.factories = [NSMutableDictionary dictionaryWithCapacity:3];
    self.active = [NSMutableDictionary dictionaryWithCapacity:3];
    self.fileManager = [NSFileManager defaultManager];
    
    // Create the application support directory for the cache.
    NSString *applicationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    applicationSupport = [applicationSupport stringByAppendingPathComponent:@"Cache"];
    [self createDirectoryAtPath:applicationSupport];
    
    // Generate our unique paths.
    self.documentsPath = [applicationSupport stringByAppendingPathComponent:self.identifier];
    self.path = [self.documentsPath stringByAppendingPathExtension:@".plist"];
    
    // Create our unique paths if necessary.
    [self createDirectoryAtPath:self.documentsPath];
    
    // Load the store.
    self.store = [ISCacheStore storeWithRoot:self.documentsPath
                                        path:self.path
                                       cache:self];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
      [[[UIAlertView alloc] initWithTitle:@"Info" message:@"Creating cache." completionBlock:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
    // Check the cache integrity.
    NSMutableArray *removals =
    [NSMutableArray arrayWithCapacity:3];
    BOOL missingFiles = NO;
    for (ISCacheItem *cacheItem in [self.store items:[ISCacheStateFilter filterWithStates:ISCacheItemStateAll]]) {
      if (cacheItem.state == ISCacheItemStateWaiting ||
          cacheItem.state == ISCacheItemStateInProgress ||
          cacheItem.state == ISCacheItemStateNotFound) {
        [cacheItem _transitionToNotFound];
        [removals addObject:cacheItem];
      } else if (cacheItem.state == ISCacheItemStateFound &&
                 ![cacheItem _filesExist]) {
        missingFiles = YES;
        [cacheItem _transitionToNotFound];
        [removals addObject:cacheItem];
      }
    }
    if (removals.count > 0) {
      [self.store removeItems:removals];
      [self.store save];
    }
    if (missingFiles) {
      NSLog(@"WARNING: Cache item files missing.");
      [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cache item files missing." completionBlock:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:self.path]];
    
    // Create and register the default factories.
    
    // HTTP Handler
    ISCacheSimpleHandlerFactory *httpFactory = [ISCacheSimpleHandlerFactory factoryWithClass:[ISCacheHTTPHandler class]];
    [self registerFactory:httpFactory
               forContext:ISCacheURLContext];
    
    // Scaling HTTP Handler
    ISCacheScalingHandlerFactory *scalingHttpfactory = [ISCacheScalingHandlerFactory new];
    [self registerFactory:scalingHttpfactory
               forContext:ISCacheImageContext];
    
    // Register for application notifications.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification object:nil];

  }
  return self;
}


- (BOOL)createDirectoryAtPath:(NSString *)path
{
  BOOL isDirectory = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
    NSError *error;
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
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
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter removeObserver:self];
}


- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
  assert([self.fileManager fileExistsAtPath:[URL path]]);
  NSError *error = nil;
  BOOL success = [URL setResourceValue:[NSNumber numberWithBool: YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
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
  // Check that there isn't an existing handler for that context.
  if ([self.factories objectForKey:context] != nil) {
    @throw [NSException exceptionWithName:ISCacheExceptionExistingFactoryForContext
                                   reason:ISCacheExceptionFactoryAlreadyRegisteredReason
                                 userInfo:nil];
  }
  
  // Register the handler.
  [self.factories setObject:factory
                    forKey:context];
}


- (void)unregisterFactoryForContext:(NSString *)context
{
  [self.factories removeObjectForKey:context];
}


// Creates a new item if one doesn't exist.
- (ISCacheItem *)cacheItem:(NSString *)item
                   context:(NSString *)context
               preferences:(NSDictionary *)preferences
{
  // Check to see if we've already created a cache item info for the
  // requested item. If we have, then return that. If not, then look
  // for the file on the file system and create an appropriate item
  // depending on whehter the file has been found or not.
  
  NSString *identifier = [self identifierForItem:item
                                         context:context
                                     preferences:preferences];
  
  // Return a pre-existing cache item.
  ISCacheItem *cacheItem = [self.store item:identifier];
  if (cacheItem) {
    return cacheItem;
  }
  
  // Create a new info for the file.
  NSString *path = [self.documentsPath stringByAppendingPathComponent:identifier];

  // If there isn't an active cache entry and something exists
  // on the file system, it represents a partial download and
  // should be cleaned up.
  BOOL isDirectory = NO;
  if ([self.fileManager fileExistsAtPath:path
                             isDirectory:&isDirectory]) {
    NSError *error;
    [self.fileManager removeItemAtPath:path
                                 error:&error];
    if (error != nil) {
      @throw [NSException exceptionWithName:ISCacheExceptionUnableToCreateItemDirectory
                                     reason:ISCacheExceptionUnableToCreateItemDirectoryReason
                                   userInfo:nil];
    }
  }
  
  // Create the cache item.
  cacheItem = [ISCacheItem _itemWithIdentifier:item
                                       context:context
                                   preferences:preferences
                                           uid:identifier
                                          root:self.documentsPath
                                          path:identifier
                                         cache:self];
  [self.store addItem:cacheItem];
  
  // Notify the observers of the new item.
  [self _notifyNewItem:cacheItem];
  
  return cacheItem;
  
}


- (ISCacheItem *)itemForIdentifier:(NSString *)identifier
                           context:(NSString *)context
                       preferences:(NSDictionary *)preferences;
{
  assert([NSThread isMainThread]);
  assert(identifier != nil);
  assert(context != nil);
  return [self cacheItem:identifier
                 context:context
             preferences:preferences];
}


- (ISCacheItem *)itemForUid:(NSString *)uid
{
  return [self.store item:uid];
}


- (ISCacheItem *)fetchItemForIdentifier:(NSString *)identifier
                                context:(NSString *)context
                            preferences:(NSDictionary *)preferences
{
  assert([NSThread isMainThread]);
  [self log:@"fetch: %@, context: %@", identifier, context];
  
  // Get the relevant details for the item.
  ISCacheItem *cacheItem = [self cacheItem:identifier
                                   context:context
                               preferences:preferences];
  
  // Once we know the item is in a valid state, we process it
  // and report the results to the callee.
  if (cacheItem.state == ISCacheItemStateFound) {
    
    // The item exists, but we update the modified date to
    // indicate that it has been accessed.
    [cacheItem _updateModified];
    [self.store save];
    
  } else if (cacheItem.state == ISCacheItemStateWaiting ||
             cacheItem.state == ISCacheItemStateInProgress) {
    
  } else {
    
    // Transition the cache item.
    [cacheItem _transitionToWaiting];
    [self.store save];
    
    // If the item doesn't exist and isn't in progress, fetch it.
    [self handlerForContext:context
                preferences:preferences
            completionBlock:^(id<ISCacheHandler> handler) {
              // Ensure the completion is always dispatched back to the main thread.
              dispatch_async(dispatch_get_main_queue(), ^{
                [cacheItem _transitionToInProgress];
                [self.active setObject:handler
                                forKey:cacheItem.uid];
                [self _fetchDidStart];
                // Notify the delegates and begin the fetch operation.
                [handler fetchItem:cacheItem
                           updater:self];
              });
            }];
    
  }
  
  return cacheItem;
  
}


- (void)removeItems:(NSArray *)items
{
  for (ISCacheItem *item in items) {
    [self removeItem:item];
  }
}


- (void)removeItem:(ISCacheItem *)cacheItem
{
  if (cacheItem.state == ISCacheItemStateFound) {
    
    // Reset the cache item state.
    [cacheItem _transitionToNotFound];
    [self.store save];
    
  } else if (cacheItem.state == ISCacheItemStateWaiting ||
             cacheItem.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, then cancel the progress.
    [self cancelItem:cacheItem];
    
  } else {
    
    // If the item doesn't exist and isn't in progress, it is
    // sufficient to do nothing.
    
  }
}


- (void)cancelItems:(NSArray *)items
{
  for (ISCacheItem *item in items) {
    [self cancelItem:item];
  }
}


- (void)cancelItem:(ISCacheItem *)cacheItem
{
  // Only attmept to cancel the item if it is in progress.
  if (cacheItem.state == ISCacheItemStateWaiting ||
      cacheItem.state == ISCacheItemStateInProgress ||
      cacheItem.state == ISCacheItemStateNotFound) {
    
    [self log:
     @"cancelItem:%@ -> item not found or in progress",
     cacheItem.uid];
    
    id<ISCacheHandler> handler = [self.active objectForKey:cacheItem.uid];
    [handler cancel];
    
    // Handlers are responsible for finalizing the
    // cache item upon cancellation.
    
  } else {
    
    [self log:
     @"cancelItem:%@ -> item already complete, ignoring",
     cacheItem.uid];
    
  }
  
}


// Return a subset of the items matching the filter.
- (NSArray *)items:(id<ISCacheFilter>)filter
{
  assert([NSThread isMainThread]);
  NSArray *items = [self.store items:filter];
  NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:3];
  for (ISCacheItem *item in items) {
    [identifiers addObject:item];
  }
  return identifiers;
}


#pragma mark - Utility methods


// Check there is a handler factory registered for the context.
// Throws an exception if no handler factory can be found.
- (void)handlerForContext:(NSString *)context
              preferences:(NSDictionary *)preferences
          completionBlock:(ISCacheHandlerFactoryCompletionBlock)completionBlock
{
  id<ISCacheHandlerFactory> factory = [self.factories objectForKey:context];
  if (factory == nil) {
    @throw [NSException exceptionWithName:ISCacheExceptionMissingFactoryForContext
                                   reason:ISCacheExceptionMissingFactoryForContextReason
                                 userInfo:nil];
  }
  [factory createHandlerForContext:context
                          userInfo:preferences
                   completionBlock:completionBlock];
}


- (void)_notifyNewItem:(ISCacheItem *)item
{
  [self.notifier notify:@selector(cacheDidUpdate:)
             withObject:self];
}


- (void)cleanupForItem:(ISCacheItem *)item
{
  id<ISCacheHandler> handler = self.active[item.uid];
  [handler finalize];
  [self.active removeObjectForKey:item.uid];
  [self _fetchDidFinish];
  [self endBackgroundTask];
}


- (void)_fetchDidStart
{
  if (self.disablesIdleTimer) {
    [[UIApplication sharedApplication] disableIdleTimer];
  }
}


- (void)_fetchDidFinish
{
  if (self.disablesIdleTimer) {
    [[UIApplication sharedApplication] enableIdleTimer];
  }
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


- (void)addCacheObserver:(id<ISCacheObserver>)observer
{
  [self.notifier addObserver:observer];
  [self log:@"+ observers (%lu), active: %lu",
   (unsigned long)self.notifier.count,
   (unsigned long)[self items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]].count];
}


- (void)removeCacheObserver:(id<ISCacheObserver>)observer
{
  [self.notifier removeObserver:observer];
  [self log:
   @"- observers (%lu), active: %lu",
   (unsigned long)self.notifier.count,
   (unsigned long)[self items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]].count];
}


- (NSString *)identifierForItem:(NSString *)item
                        context:(NSString *)context
                    preferences:(NSDictionary *)preferences
{
  if (preferences) {
    return [[NSString stringWithFormat:
             @"%@:%@(%@)",
             context,
             item,
             preferences] md5];
  } else {
    return [[NSString stringWithFormat:
             @"%@:%@",
             context,
             item] md5];
  }
}


// Callback handle for the handlers.
// Should not be used internally as a notification mechanism.
- (void)itemDidUpdate:(ISCacheItem *)item
{
  [self.store save];
}


- (void)itemDidFinish:(ISCacheItem *)item
{
  [self log:@"itemDidFinish:%@", item.uid];
  [item _transitionToFound];
  [self.store save];
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
  [self.store save];
  [self cleanupForItem:item];
}


- (void)item:(ISCacheItem *)item
didFailWithError:(NSError *)error
{
  [self log:@"item:%@ didFailWithError: %@", item.uid, error];
  [item _transitionToError:error];
  [self.store save];
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
