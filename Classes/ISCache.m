//
//  ISItemCache.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 28/07/2013.
//
//

#import "ISCache.h"
#import "ISNotifier.h"
#import "ISCacheObserverBlock.h"
#import "ISSimpleCacheHandlerFactory.h"
#import "NSString+MD5.h"
#import "ISCacheStore.h"


// TODO Items need to be timestamped and it should be possible to
// differentiate between permanently cached items and temporarily
// cached items.

// TODO Handlers should have an expiry strategy.

@interface ISCache ()

@property (nonatomic, strong) ISNotifier *notifier;
@property (nonatomic, strong) NSMutableDictionary *factories;
@property (nonatomic, strong) NSMutableDictionary *active;
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, strong) NSString *documentsPath;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) ISCacheStore *store;

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
    
    // Load the store.
    self.store = [ISCacheStore storeWithPath:self.path];
    
    // Clean up any partially downloaded files.
    NSArray *incompleteItems = [self.store items:ISCacheItemStateInProgress];
    if (incompleteItems.count > 0) {
      for (ISCacheItem *item in [self.store items:ISCacheItemStateInProgress]) {
        [item deleteFile];
        [self.store removeItem:item];
      }
      [self.store save];
    }

    // TODO Should this be set by the user or should it have an
    // additional stub in there for the current path instance?
    self.documentsPath
    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                           NSUserDomainMask,
                                           YES) objectAtIndex:0];
    
    // Create and register the default factories.
    
    // HTTP Handler
    ISSimpleCacheHandlerFactory *httpFactory = [ISSimpleCacheHandlerFactory factoryWithClass:[ISHTTPCacheHandler class]];
    [self registerFactory:httpFactory
               forContext:ISCacheContextURL];
    
    // Scaling HTTP Handler
    ISScalingCacheHandlerFactory *scalingHttpfactory = [ISScalingCacheHandlerFactory new];
    [self registerFactory:scalingHttpfactory
               forContext:ISCacheContextScaleURL];

  }
  return self;
}


- (void)registerFactory:(id<ISCacheHandlerFactory>)factory
             forContext:(NSString *)context
{
  // Check that there isn't an existing handler for that context.
  if ([self.factories objectForKey:context] != nil) {
    @throw [NSException exceptionWithName:@"FactoryRegistered"
                                   reason:@"A cache handler factory has already been registered for the specified protocol."
                                 userInfo:nil];
  }
  
  // Register the handler.
  [self.factories setObject:factory
                    forKey:context];
}


// Returns an existing item info or nil.
- (ISCacheItem *)cacheItemInfoForIdentifier:(NSString *)identifier
{
  return [self.store item:identifier];
}


// Creates a new item info if one doesn't exist.
- (ISCacheItem *)cacheItemInfoForItem:(NSString *)item
                                  context:(NSString *)context
                                 userInfo:(NSDictionary *)userInfo
{
  // Check to see if we've already created a cache item info for the
  // requested item. If we have, then return that. If not, then look
  // for the file on the file system and create an appropriate info
  // depending on whehter the file has been found or not.
  
  NSString *identifier = [self identifierForItem:item
                                         context:context
                                        userInfo:userInfo];
  
  // Return a pre-existing cache item info.
  ISCacheItem *info = [self cacheItemInfoForIdentifier:identifier];
  if (info) {
    return info;
  }
  
  // Create a new info for the file.
  info = [ISCacheItem new];
  info.item = item;
  info.context = context;
  info.userInfo = userInfo;
  info.identifier = identifier;
  info.path = [self.documentsPath stringByAppendingPathComponent:identifier];
  [self resetInfo:info];
  
  [self.store addItem:info];
  [self.store save];
  
  // If there isn't an active cache entry and something exists
  // on the file system, it represents a partial download and
  // should be cleaned up.
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:info.path
                        isDirectory:NO]) {
    NSError *error;
    [fileManager removeItemAtPath:info.path
                            error:&error];
    if (error != nil) {
      // TODO What do we do in the case of an error?
    }
  }
  
  return info;
  
}


- (ISCacheItem *)infoForItem:(NSString *)item
                         context:(NSString *)context
                        userInfo:(NSDictionary *)userInfo;
{
  return [self cacheItemInfoForItem:item
                            context:context
                           userInfo:userInfo];
}


- (NSString *)item:(NSString *)item
           context:(NSString *)context
          userInfo:(NSDictionary *)userInfo
             block:(ISCacheBlock)completionBlock
{
  // Assert that we have a valid completion block.
  NSAssert(completionBlock != NULL, @"Completion block must be non-NULL.");
  
  // Get the relevant details for the item.
  NSString *identifier = [self identifierForItem:item
                                         context:context
                                        userInfo:userInfo];
  ISCacheItem *info = [self cacheItemInfoForItem:item
                                             context:context
                                            userInfo:userInfo];
  
  // Before proceeding we check to see if, in the case of an
  // item which is present in the cache, the file has been removed
  // unexpectedly. This can happen if we are relying on Apple's
  // mechanisms for cached files.
  if (info.state == ISCacheItemStateFound) {
    
    // Check that there is a file on disk matching the cache item.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:info.path
                           isDirectory:NO]) {
      [self resetInfo:info];
    }
    
  }
  
  // Once we know the item is in a valid state, we process it
  // and report the results to the callee.
  if (info.state == ISCacheItemStateFound) {
    
    // If the item exists, call back with the result.
    completionBlock(info, nil);
    
  } else if (info.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, attach a block observer.
    ISCacheObserverBlock *observer
    = [ISCacheObserverBlock observerWithIdentifier:identifier
                                             block:completionBlock
                                             cache:self];
    [self.observers addObject:observer];
    [self addObserver:observer];
    
  } else {
    
    // Set the state to in progress.
    info.state = ISCacheItemStateInProgress;
    
    // If the item doesn't exist and isn't in progress, fetch it.
    id<ISCacheHandler> handler = [self handlerForContext:context
                                                userInfo:userInfo];

    [self.active setObject:handler
                    forKey:identifier];
    
    if (completionBlock) {
      ISCacheObserverBlock *observer
      = [ISCacheObserverBlock observerWithIdentifier:identifier
                                               block:completionBlock
                                               cache:self];
      [self.observers addObject:observer];
      [self addObserver:observer];
    }
    
    // Notify the delegates.
    [self notifyObservers:info];
    
    // Begin the fetch.
    [handler fetchItem:info
              delegate:self];
    
  }
  
  return identifier;
  
}


- (void)removeItems:(NSArray *)identifiers
{
  for (NSString *identifier in identifiers) {
    [self removeItem:identifier];
  }
}


- (void)removeItem:(NSString *)identifier
{
  // Get the relevant details for the item.
  ISCacheItem *info = [self cacheItemInfoForIdentifier:identifier];
  
  // If the cache info is nil we assume that no entry exists.
  if (info == nil) {
    return;
  }
  
  if (info.state == ISCacheItemStateFound) {
    
    // If the item exists, simply delete the file at the path
    // and notify any cache observers.
    
    // Remove the file.
    [info deleteFile];
    
    // Reset the cache item state.
    [self resetInfo:info];
    
    // Update the cache.
    [self.store removeItem:info];
    [self.store save];
    
    // Notify the observers that the item has been removed.
    [self notifyObservers:info];
    
  } else if (info.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, then cancel the progress.
    [self cancelItem:info.identifier];
    
  } else {
    
    // If the item doesn't exist and isn't in progress, it is
    // sufficient to do nothing.
    
  }
}


- (void)cancelItems:(NSArray *)identifiers
{
  for (NSString *identifier in identifiers) {
    [self cancelItem:identifier];
  }
}


- (void)cancelItem:(NSString *)identifier
{
  // Get the relevant details for the item.
  ISCacheItem *info = [self cacheItemInfoForIdentifier:identifier];
  
  // If the cache info is nil we assume that no entry exists.
  if (info == nil) {
    if (self.debug) {
      NSLog(@"cancelItem:%@ -> no item exists",
            identifier);
    }
    return;
  }

  // Only attmept to cancel the item if it is in progress.
  if (info.state == ISCacheItemStateInProgress ||
      info.state == ISCacheItemStateNotFound) {
    
    if (self.debug) {
      NSLog(@"cancelItem:%@ -> item not found or in progress",
            identifier);
    }
    
    id<ISCacheHandler> handler = [self.active objectForKey:identifier];
    [handler cancel];
    
    // Delete the file.
    [info deleteFile];
    
    // Remove the item.
    [self.store removeItem:info];
    [self.store save];
    
    // Notify the observers.
    info.state = ISCacheItemStateNotFound;
    NSError *error = [NSError errorWithDomain:ISCacheErrorDomain
                                         code:ISCacheErrorCancelled
                                     userInfo:nil];
    [self notifyObservers:info
                    error:error];
    
  } else {
    
    if (self.debug) {
      NSLog(@"cancelItem:%@ -> item already complete, ignoring",
            identifier);
    }
    
  }
  
}


// Return a subset of the items matching the filter.
- (NSArray *)identifiers:(int)filter
{
  NSArray *items = [self.store items:filter];
  NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:3];
  for (ISCacheItem *item in items) {
    [identifiers addObject:item.identifier];
  }
  return identifiers;
}


#pragma mark - Utility methods


// TODO Should this be a method on ISCacheItemInfo?
- (void)resetInfo:(ISCacheItem *)info
{
  info.state = ISCacheItemStateNotFound;
  info.totalBytesExpectedToRead = ISCacheItemTotalBytesUnknown;
  info.totalBytesRead = 0;
}


// Check there is a handler factory registered for the context.
// Throws an exception if no handler factory can be found.
- (id<ISCacheHandler>)handlerForContext:(NSString *)context
                               userInfo:(NSDictionary *)userInfo
{
  id<ISCacheHandlerFactory> factory = [self.factories objectForKey:context];
  if (factory == nil) {
    @throw [NSException exceptionWithName:@"MissingHandler"
                                   reason:@"No cache handler has been registered for the specified protocol."
                                 userInfo:nil];
  }
  return [factory createHandler:userInfo];
}


- (void)notifyObservers:(ISCacheItem *)info
{
  [self.notifier notify:@selector(itemDidUpdate:)
             withObject:info];
}

- (void)notifyObservers:(ISCacheItem *)info
                  error:(NSError *)error
{
  [self.notifier notify:@selector(item:didFailwithError:)
             withObject:info
             withObject:error];
}




#pragma mark - Observer methods


- (void)addObserver:(id<ISCacheObserver>)observer
{
  [self.notifier addObserver:observer];
  if (self.debug) {
    NSLog(@"+ observers (%lu)", (unsigned long)self.notifier.count);
    NSLog(@"active: %lu", (unsigned long)[self identifiers:ISCacheItemStateInProgress].count);
  }
}


- (void)removeObserver:(id<ISCacheObserver>)observer
{
  [self.notifier removeObserver:observer];
  if (self.debug) {
    NSLog(@"- observers (%lu)", (unsigned long)self.notifier.count);
    NSLog(@"active: %lu", (unsigned long)[self identifiers:ISCacheItemStateInProgress].count);
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
- (void)itemDidUpdate:(ISCacheItem *)info
{
  // Upgrade the item state to 'in progress' if
  // the number of expected bytes has been set.
  if (info.totalBytesExpectedToRead
      != ISCacheItemTotalBytesUnknown) {
    info.state = ISCacheItemStateInProgress;
  }
  [self notifyObservers:info];
}


- (void)itemDidFinish:(ISCacheItem *)info
{
  // Update the item info with the appropriate state.
  info.state = ISCacheItemStateFound;
  [info closeFile];
  
  // Delete the handler for the file.
  [self.active removeObjectForKey:info.identifier];
  
  // Save the store as the state of one of the items has changed.
  [self.store save];

  // Notify our observers.
  [self notifyObservers:info];
  
  // Block delegates will delete themselves when they encounter
  // an ISCacheItemStateFound for the item. This means there is
  // no further cleanup required here.
}


- (void)item:(ISCacheItem *)info
didFailWithError:(NSError *)error
{
  if (self.debug) {
    NSLog(@"item:didFailWithError: %@", error);
  }
  
  // Update the state of the cached item.
  info.state = ISCacheItemStateNotFound;
  
  // Delete the partially downloaded file.
  [info deleteFile];
  
  // Notify the observers of the error.
  [self notifyObservers:info
                  error:error];
  
  // Remove the reference to the item.
  [self.store removeItem:info];
  [self.store save];
}


@end
