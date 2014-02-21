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
#import "ISCacheSimpleHandlerFactory.h"
#import "ISCacheStore.h"
#import "NSString+Hashes.h"
#import "ISCachePrivate.h"
#import "ISCacheItemPrivate.h"

// Informal properties.
NSString *const ISCacheItemDescription = @"description";
NSString *const ISCacheItemThumbnail = @"thumbnail";

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
      
      NSString *documentsPath
      = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                             NSUserDomainMask,
                                             YES) objectAtIndex:0];
      NSString *path = [documentsPath stringByAppendingPathComponent:@"uk.co.inseven.cache.store.plist"];
      
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
    self.fileManager = [NSFileManager defaultManager];
    
    // Load the store.
    self.store = [ISCacheStore storeWithPath:self.path
                                       cache:self];
    
    // Clean up any partially downloaded files.
    BOOL needsSave = NO;
    for (ISCacheItem *item in [self.store items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress | ISCacheItemStateNotFound]]) {
      needsSave = YES;
      [item _transitionToNotFound];
      [self.store removeItem:item];
    }
    if (needsSave) {
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
                                   [self.path md5]]];
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
  cacheItem = [ISCacheItem _itemWithIdentifier:item
                                       context:context
                                   preferences:preferences
                                           uid:identifier
                                          path:path
                                         cache:self];
  [self.store addItem:cacheItem];
  
  // Notify the observers of the new item.
  [self notifyNewItem:cacheItem];
  
  // If there isn't an active cache entry and something exists
  // on the file system, it represents a partial download and
  // should be cleaned up.
  // TODO This clean up code needs to be restored for a given
  // cache item.
//  BOOL isDirectory = NO;
//  if ([self.fileManager fileExistsAtPath:cacheItem.file.path
//                             isDirectory:&isDirectory]) {
//    NSError *error;
//    [self.fileManager removeItemAtPath:cacheItem.file.path
//                                 error:&error];
//    if (error != nil) {
//      @throw [NSException exceptionWithName:ISCacheExceptionUnableToCreateItemDirectory
//                                     reason:ISCacheExceptionUnableToCreateItemDirectoryReason
//                                   userInfo:nil];
//    }
//  }
  
  return cacheItem;
  
}


- (ISCacheItem *)itemForIdentifier:(NSString *)identifier
                           context:(NSString *)context
                       preferences:(NSDictionary *)preferences;
{
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
  [self log:@"fetch: %@, context: %@", identifier, context];
  
  // Get the relevant details for the item.
  ISCacheItem *cacheItem = [self cacheItem:identifier
                                   context:context
                               preferences:preferences];
  
  // Before proceeding we check to see if, in the case of an
  // item which is present in the cache, the file has been removed
  // unexpectedly. This can happen if we are relying on Apple's
  // mechanisms for cached files.
  if (cacheItem.state == ISCacheItemStateFound) {
    
    // Check that there is a file on disk matching the cache item.
    if (![cacheItem _filesExist]) {
      [cacheItem _transitionToNotFound];
      [self.store save];
    }
    
  }
  
  // Once we know the item is in a valid state, we process it
  // and report the results to the callee.
  if (cacheItem.state == ISCacheItemStateFound) {
    
    // The item exists, but we update the modified date to
    // indicate that it has been accessed.
    [cacheItem _updateModified];
    [self.store save];
    
  } else if (cacheItem.state == ISCacheItemStateInProgress) {
    
  } else {
    
    // Transition the cache item.
    [cacheItem _transitionToInProgress];
    [self.store save];
    
    // If the item doesn't exist and isn't in progress, fetch it.
    id<ISCacheHandler> handler = [self handlerForContext:context
                                             preferences:preferences];

    [self.active setObject:handler
                    forKey:cacheItem.uid];
    
    // Notify the delegates and begin the fetch operation
    // asynchronously. This ensures that any calling code can
    // set up filters, etc based on the returned ISCacheItem before
    // the operation begins ensuring they do not miss a callback.
    // Assuming ISCache is only accessed from the main thread, we
    // calling code is guaranteed never to miss any updates which
    // occur any time after calling fetchItem.
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
      
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
    
    // Reset the cache item state.
    [item _transitionToNotFound];
    [self.store save];
    
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
    
    [self log:
     @"cancelItem:%@ -> item not found or in progress",
     item.uid];
    
    id<ISCacheHandler> handler = [self.active objectForKey:item.uid];
    [handler cancel];
    
    // Transition the cache item.
    // This will close and clean up any partial files.
    NSError *error =
    [NSError errorWithDomain:ISCacheErrorDomain
                        code:ISCacheErrorCancelled
                    userInfo:nil];
    [item _transitionToError:error];
    [self.store save];
    
  } else {
    
    [self log:
     @"cancelItem:%@ -> item already complete, ignoring",
     item.uid];
    
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


// Check there is a handler factory registered for the context.
// Throws an exception if no handler factory can be found.
- (id<ISCacheHandler>)handlerForContext:(NSString *)context
                            preferences:(NSDictionary *)preferences
{
  id<ISCacheHandlerFactory> factory = [self.factories objectForKey:context];
  if (factory == nil) {
    @throw [NSException exceptionWithName:ISCacheExceptionMissingFactoryForContext
                                   reason:ISCacheExceptionMissingFactoryForContextReason
                                 userInfo:nil];
  }
  return [factory createHandler:preferences];
}


- (void)notifyNewItem:(ISCacheItem *)item
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.notifier notify:@selector(cacheDidUpdate:)
               withObject:self];
  });
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
  // Update the item info with the appropriate state.
  [item _transitionToFound];
  [self.store save];
  
  // Delete the handler for the file.
  [self.active removeObjectForKey:item.uid];
}


- (void)item:(ISCacheItem *)item
didFailWithError:(NSError *)error
{
  [self log:@"item:didFailWithError: %@", error];
  [item _transitionToError:error];
  [self.store save];
}


@end
