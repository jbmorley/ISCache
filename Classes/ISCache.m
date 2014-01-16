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

#import "ISCache.h"
#import "ISNotifier.h"
#import "ISCacheBlockObserver.h"
#import "ISCacheSimpleHandlerFactory.h"
#import "NSString+MD5.h"
#import "ISCacheStore.h"

@interface ISCache ()

@property (nonatomic, strong) ISNotifier *notifier;
@property (nonatomic, strong) NSMutableDictionary *factories;
@property (nonatomic, strong) NSMutableDictionary *active;
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, strong) NSString *documentsPath;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) ISCacheStore *store;
@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation ISCache

static ISCache *sCache;


+ (id)defaultCache
{
  @synchronized (self) {
    if (sCache == nil) {
      
      NSString *documentsPath
      = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                             NSUserDomainMask,
                                             YES) objectAtIndex:0];
      NSString *path = [documentsPath stringByAppendingPathComponent:@"uk.co.inseven.cache.State.plist"];
      
      sCache = [[self alloc] initWithPath:path];
    }
    return sCache;
  }
}


- (id)initWithPath:(NSString *)path
{
  self = [super init];
  if (self) {
    self.debug = NO;
    self.path = path;
    self.notifier = [ISNotifier new];
    self.factories = [NSMutableDictionary dictionaryWithCapacity:3];
    self.active = [NSMutableDictionary dictionaryWithCapacity:3];
    self.observers = [NSMutableArray arrayWithCapacity:3];
    self.fileManager = [NSFileManager defaultManager];
    
    // Load the store.
    self.store = [ISCacheStore storeWithPath:self.path];
    
    // Clean up any partially downloaded files.
    NSArray *incompleteItems = [self.store items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]];
    if (incompleteItems.count > 0) {
      for (ISCacheItem *item in [self.store items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]]) {
        [item deleteFile];
        [self.store removeItem:item];
      }
      [self.store save];
    }

    // Generate a unique path for the cache items.
    self.documentsPath
    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                           NSUserDomainMask,
                                           YES) objectAtIndex:0];
    self.documentsPath =
    [NSString pathWithComponents:@[self.documentsPath,
                                   @"Cache",
                                   [self.path MD5]]];
    BOOL isDirectory = NO;
    if (![self.fileManager fileExistsAtPath:self.documentsPath
                                isDirectory:&isDirectory]) {
      NSError *error;
      [self.fileManager createDirectoryAtPath:self.documentsPath
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:&error];
      if (error) {
        
      }
    }
    
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


// Creates a new item if one doesn't exist.
- (ISCacheItem *)cacheItem:(NSString *)item
                   context:(NSString *)context
                  userInfo:(NSDictionary *)userInfo
{
  // Check to see if we've already created a cache item info for the
  // requested item. If we have, then return that. If not, then look
  // for the file on the file system and create an appropriate item
  // depending on whehter the file has been found or not.
  
  NSString *identifier = [self identifierForItem:item
                                         context:context
                                        userInfo:userInfo];
  
  // Return a pre-existing cache item.
  ISCacheItem *cacheItem = [self.store item:identifier];
  if (cacheItem) {
    return cacheItem;
  }
  
  // Create a new info for the file.
  NSString *path = [self.documentsPath stringByAppendingPathComponent:identifier];
  cacheItem = [ISCacheItem itemWithIdentifier:item
                                context:context
                               userInfo:userInfo
                                    uid:identifier
                                   path:path];
  [self resetItem:cacheItem];
  
  [self.store addItem:cacheItem];
  [self.store save];
  
  // If there isn't an active cache entry and something exists
  // on the file system, it represents a partial download and
  // should be cleaned up.
  BOOL isDirectory = NO;
  if ([self.fileManager fileExistsAtPath:cacheItem.path
                             isDirectory:&isDirectory]) {
    NSError *error;
    [self.fileManager removeItemAtPath:cacheItem.path
                                 error:&error];
    if (error != nil) {
      @throw [NSException exceptionWithName:ISCacheExceptionUnableToCreateItemDirectory
                                     reason:ISCacheExceptionUnableToCreateItemDirectoryReason
                                   userInfo:nil];
    }
  }
  
  return cacheItem;
  
}


- (ISCacheItem *)itemForIdentifier:(NSString *)item
                           context:(NSString *)context
                          userInfo:(NSDictionary *)userInfo;
{
  return [self cacheItem:item
                            context:context
                           userInfo:userInfo];
}


- (ISCacheItem *)fetchItemForIdentifier:(NSString *)item
                                context:(NSString *)context
                               userInfo:(NSDictionary *)userInfo
                                  block:(ISCacheBlock)completionBlock
{
  // Assert that we have a valid completion block.
  NSAssert(completionBlock != NULL, @"Completion block must be non-NULL.");
  
  // Get the relevant details for the item.
  ISCacheItem *cacheItem = [self cacheItem:item
                                   context:context
                                  userInfo:userInfo];
  
  // Before proceeding we check to see if, in the case of an
  // item which is present in the cache, the file has been removed
  // unexpectedly. This can happen if we are relying on Apple's
  // mechanisms for cached files.
  if (cacheItem.state == ISCacheItemStateFound) {
    
    // Check that there is a file on disk matching the cache item.
    BOOL isDirectory = NO;
    if (![self.fileManager fileExistsAtPath:cacheItem.path
                                isDirectory:&isDirectory]) {
      [self resetItem:cacheItem];
    }
    
  }
  
  // Once we know the item is in a valid state, we process it
  // and report the results to the callee.
  if (cacheItem.state == ISCacheItemStateFound) {
    
    // The item exists, but we update the modified date to
    // indicate that it has been accessed.
    cacheItem.modified = [NSDate new];
    
    // Save the cache store to reflect the updated cache item.
    [self.store save];
    
    // If the item exists, call back with the result.
    completionBlock(cacheItem);
    
  } else if (cacheItem.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, attach a block observer.
    ISCacheBlockObserver *observer
    = [ISCacheBlockObserver observerWithItem:cacheItem
                                       block:completionBlock];
    [self.observers addObject:observer];
    [self addObserver:observer];
    
  } else {
    
    // Set the state to in progress.
    cacheItem.state = ISCacheItemStateInProgress;
    cacheItem.created = [NSDate new];
    cacheItem.modified = cacheItem.created;

    // Save the cache store to reflect this state change.
    [self.store save];
    
    // If the item doesn't exist and isn't in progress, fetch it.
    id<ISCacheHandler> handler = [self handlerForContext:context
                                                userInfo:userInfo];

    [self.active setObject:handler
                    forKey:cacheItem.uid];
    
    if (completionBlock) {
      ISCacheBlockObserver *observer
      = [ISCacheBlockObserver observerWithItem:cacheItem
                                         block:completionBlock];
      [self.observers addObject:observer];
      [self addObserver:observer];
    }
    
    // Notify the delegates and begin the fetch operation
    // asynchronously. This ensures that any calling code can
    // set up filters, etc based on the returned ISCacheItem before
    // the operation begins ensuring they do not miss a callback.
    // Assuming ISCache is only accessed from the main thread, we
    // calling code is guaranteed never to miss any updates which
    // occur any time after calling fetchItem.
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
      
      // Notify the delegates.
      [self notifyObservers:cacheItem];
      
      // Begin the fetch.
      [handler fetchItem:cacheItem
                delegate:self];
      
    });
    
  }
  
  return cacheItem;
  
}


- (void)removeItems:(NSArray *)items
{
  for (ISCacheItem *item in items) {
    [self removeItem:item];
  }
}


- (void)removeItem:(ISCacheItem *)item
{
  if (item.state == ISCacheItemStateFound) {
    
    // If the item exists, simply delete the file at the path
    // and notify any cache observers.
    
    // Remove the file.
    [item deleteFile];
    
    // Reset the cache item state.
    [self resetItem:item];
    
    // Update the cache.
    // We do not remove the item during the life-time of the cache
    // to ensure it remains a unique instance of that cache item
    // during the running of the application.
    // We do, however, save the store to cache its new state.
    [self.store save];
    
    // Notify the observers that the item has been removed.
    [self notifyObservers:item];
    
  } else if (item.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, then cancel the progress.
    [self cancelItem:item];
    
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


- (void)cancelItem:(ISCacheItem *)item
{
  // Only attmept to cancel the item if it is in progress.
  if (item.state == ISCacheItemStateInProgress ||
      item.state == ISCacheItemStateNotFound) {
    
    if (self.debug) {
      NSLog(@"cancelItem:%@ -> item not found or in progress",
            item.uid);
    }
    
    id<ISCacheHandler> handler = [self.active objectForKey:item.uid];
    [handler cancel];
    
    // Delete the file.
    [item deleteFile];
    
    // Remove the item.
    // Update the cache.
    // We do not remove the item during the life-time of the cache
    // to ensure it remains a unique instance of that cache item
    // during the running of the application.
    // We do, however, save the store to cache its new state.
    [self.store save];
    
    // Set an appropriate error for the item.
    item.lastError = [NSError errorWithDomain:ISCacheErrorDomain
                                         code:ISCacheErrorCancelled
                                     userInfo:nil];
    
    // Update the item state.
    item.state = ISCacheItemStateNotFound;

    [self notifyObservers:item];
    
  } else {
    
    if (self.debug) {
      NSLog(@"cancelItem:%@ -> item already complete, ignoring",
            item.uid);
    }
    
  }
  
}


// Return a subset of the items matching the filter.
- (NSArray *)items:(id<ISCacheFilter>)filter
{
  NSArray *items = [self.store items:filter];
  NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:3];
  for (ISCacheItem *item in items) {
    [identifiers addObject:item];
  }
  return identifiers;
}


#pragma mark - Utility methods


- (void)resetItem:(ISCacheItem *)item
{
  item.state = ISCacheItemStateNotFound;
  item.totalBytesExpectedToRead = ISCacheItemTotalBytesUnknown;
  item.totalBytesRead = 0;
  item.lastError = nil;
  item.created = nil;
  item.modified = nil;
}


// Check there is a handler factory registered for the context.
// Throws an exception if no handler factory can be found.
- (id<ISCacheHandler>)handlerForContext:(NSString *)context
                               userInfo:(NSDictionary *)userInfo
{
  id<ISCacheHandlerFactory> factory = [self.factories objectForKey:context];
  if (factory == nil) {
    @throw [NSException exceptionWithName:ISCacheExceptionMissingFactoryForContext
                                   reason:ISCacheExceptionMissingFactoryForContextReason
                                 userInfo:nil];
  }
  return [factory createHandler:userInfo];
}


- (void)notifyObservers:(ISCacheItem *)item
{
  [self.notifier notify:@selector(cache:itemDidUpdate:)
             withObject:self
             withObject:item];
}


#pragma mark - Observer methods


- (void)addObserver:(id<ISCacheObserver>)observer
{
  [self.notifier addObserver:observer];
  if (self.debug) {
    NSLog(@"+ observers (%lu)", (unsigned long)self.notifier.count);
    NSLog(@"active: %lu", (unsigned long)[self items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]].count);
  }
}


- (void)removeObserver:(id<ISCacheObserver>)observer
{
  [self.notifier removeObserver:observer];
  if (self.debug) {
    NSLog(@"- observers (%lu)", (unsigned long)self.notifier.count);
    NSLog(@"active: %lu", (unsigned long)[self items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]].count);
  }
}


- (NSString *)identifierForItem:(NSString *)item
                        context:(NSString *)context
                       userInfo:(NSDictionary *)userInfo
{
  if (userInfo) {
    return [[NSString stringWithFormat:
             @"%@:%@(%@)",
             context,
             item,
             userInfo] MD5];
  } else {
    return [[NSString stringWithFormat:
             @"%@:%@",
             context,
             item] MD5];
  }
}


// Callback handle for the handlers.
// Should not be used internally as a notification mechanism.
- (void)itemDidUpdate:(ISCacheItem *)item
{
  // Upgrade the item state to 'in progress' if
  // the number of expected bytes has been set.
  if (item.totalBytesExpectedToRead
      != ISCacheItemTotalBytesUnknown) {
    item.state = ISCacheItemStateInProgress;
  }
  [self notifyObservers:item];
}


- (void)itemDidFinish:(ISCacheItem *)item
{
  // Update the item info with the appropriate state.
  item.state = ISCacheItemStateFound;
  [item closeFile];
  
  // Delete the handler for the file.
  [self.active removeObjectForKey:item.uid];
  
  // Save the store as the state of one of the items has changed.
  [self.store save];

  // Notify our observers.
  [self notifyObservers:item];
  
  // Block delegates will delete themselves when they encounter
  // an ISCacheItemStateFound for the item. This means there is
  // no further cleanup required here.
}


- (void)item:(ISCacheItem *)item
didFailWithError:(NSError *)error
{
  if (self.debug) {
    NSLog(@"item:didFailWithError: %@", error);
  }
  
  // Since we are offering explicit support for KVO, we should
  // must ensure these modifications to the ISCacheItem are
  // performed in the correct order.
  // In the future, it may be appropriate to add selectors to
  // the ISCacheItem to support setting these states 'atomically'.
  
  // Delete the partially downloaded file.
  [item deleteFile];
  
  // Cache the last error.
  item.lastError = error;
  
  // Update the state of the cached item.
  // If people are making use of KVO they are highly likely to be
  // observing the state property.
  item.state = ISCacheItemStateNotFound;
  
  // Notify the observers of the error.
  // We do this via the normal notification mechanism and require
  // clients to inspect the item when in the
  // ISCacheItemStateNotFound state to see if an error has been
  // encountered.
  [self notifyObservers:item];
  
  // Update the state of the item.
  [self.store save];
}


@end
