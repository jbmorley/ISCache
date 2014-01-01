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


// TODO Items need to be timestamped and it should be possible to
// differentiate between permanently cached items and temporarily
// cached items.

// TODO Handlers should have an expiry strategy.

@interface ISCache ()

@property (nonatomic, strong) ISNotifier *notifier;
@property (nonatomic, strong) NSMutableDictionary *factories;
@property (nonatomic, strong) NSMutableDictionary *active;
@property (nonatomic, strong) NSMutableDictionary *items;
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, strong) NSMutableDictionary *info;
@property (nonatomic, strong) NSString *documentsPath;
@property (nonatomic, strong) NSString *path;

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
    self.path = path;
    self.notifier = [ISNotifier new];
    self.factories = [NSMutableDictionary dictionaryWithCapacity:3];
    self.active = [NSMutableDictionary dictionaryWithCapacity:3];
    
    // Load the cache state if present.
    self.items = [NSMutableDictionary dictionaryWithCapacity:3];
    self.info = [NSMutableDictionary dictionaryWithCapacity:3];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path
                                             isDirectory:NO]) {
      NSDictionary *items = [NSDictionary dictionaryWithContentsOfFile:self.path];
      for (NSString *identifier in items) {
        ISCacheItemInfo *info = [ISCacheItemInfo itemInfoWithDictionary:items[identifier]];
        [self.items setObject:items[identifier]
                       forKey:identifier];
        [self.info setObject:info
                      forKey:identifier];
      }
    }
    
    self.observers = [NSMutableArray arrayWithCapacity:3];
    
    self.documentsPath
    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                           NSUserDomainMask,
                                           YES) objectAtIndex:0];
    
    // Create and register the default factories.
    
    // HTTP Handler
    ISSimpleCacheHandlerFactory *httpFactory = [ISSimpleCacheHandlerFactory factoryWithClass:[ISHTTPCacheHandler class]];
    [self registerFactory:httpFactory
               forContext:kCacheContextURL];
    
    // Scaling HTTP Handler
    ISScalingCacheHandlerFactory *scalingHttpfactory = [ISScalingCacheHandlerFactory new];
    [self registerFactory:scalingHttpfactory
               forContext:kCacheContextScaleURL];

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
- (ISCacheItemInfo *)cacheItemInfoForIdentifier:(NSString *)identifier
{
  // Look for an existing active info.
  return [self.info objectForKey:identifier];
}


// Creates a new item info if one doesn't exist.
- (ISCacheItemInfo *)cacheItemInfoForItem:(NSString *)item
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
  ISCacheItemInfo *info = [self cacheItemInfoForIdentifier:identifier];
  if (info) {
    return info;
  }
  
  // Create a new info for the file.
  info = [ISCacheItemInfo new];
  info.item = item;
  info.context = context;
  info.userInfo = userInfo;
  info.identifier = identifier;
  info.path = [self.documentsPath stringByAppendingPathComponent:identifier];
  info.state = ISCacheItemStateNotFound;
  info.totalBytesExpectedToRead = ISCacheItemTotalBytesUnknown;
  info.totalBytesRead = 0;
  
  [self.info setObject:info
                forKey:identifier];
  
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


- (ISCacheItemInfo *)infoForItem:(NSString *)item
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
  ISCacheItemInfo *info = [self cacheItemInfoForItem:item
                                             context:context
                                            userInfo:userInfo];
  
  if (info.state == ISCacheItemStateFound) {
    
    // Check that there is a file on disk matching the cache item.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:info.path
                           isDirectory:NO]) {
      // TODO We should recover from this scenario but at the moment doing so
      // would mask some problems so this needs to be fixed later.
    }
    
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
    info.state = ISCacheItemStatePending;
    
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
  ISCacheItemInfo *info = [self cacheItemInfoForIdentifier:identifier];
  
  // If the cache info is nil we assume that no entry exists.
  if (info == nil) {
    return;
  }
  
  if (info.state == ISCacheItemStateFound) {
    
    // If the item exists, simply delete the file at the path
    // and notify any cache observers.
    
    // Close the file in case it's open.
    [info closeFile];
    
    // Delete the file.
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:info.path
                            error:&error];
    if (error) {
      // TODO Handle an error in deleting the file.
      // What can we actually do here if the file wasn't correctly
      // deleted?
    }
    
    // Reset the cache item state.
    info.state = ISCacheItemStateNotFound;
    info.totalBytesExpectedToRead = 0;
    info.totalBytesRead = 0;
    
    // Update the cache.
    [self.info removeObjectForKey:info.identifier];
    [self.items removeObjectForKey:info.identifier];
    [self.items writeToFile:self.path
                 atomically:YES];
    
    // Notify the observers that the item has been removed.
    [self notifyObservers:info];
    
  } else if (info.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, then cancel the progress.
    // This should be sufficient to cause the cache item to be
    // removed.
    id<ISCacheHandler> handler = [self.active objectForKey:identifier];
    [handler cancel];
    
    // TODO Determine how the observers are notified in this
    // mechanism. I think it should come from the handler.
    
    // TODO Remove the object from the cache?
    
  } else {
    
    // If the item doesn't exist and isn't in progress, it is
    // sufficient to do nothing.
    
  }
}


- (NSArray *)cacheItems
{
  // Return the superset of cached items of all states.
  // TODO We may wish to provide a filter for item states?
  return [[self.info keyEnumerator] allObjects];
}


#pragma mark - Utility methods


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


- (void)notifyObservers:(ISCacheItemInfo *)info
{
  [self.notifier notify:@selector(itemDidUpdate:)
             withObject:info];
}


#pragma mark - Observer methods


- (void)addObserver:(id<ISCacheObserver>)observer
{
  [self.notifier addObserver:observer];
  NSLog(@"Observers: %d", self.notifier.count);
}


- (void)removeObserver:(id<ISCacheObserver>)observer
{
  [self.notifier removeObserver:observer];
  NSLog(@"Observers: %d", self.notifier.count);
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
- (void)itemDidUpdate:(ISCacheItemInfo *)info
{
  // Upgrade the item state to 'in progress' if
  // the number of expected bytes has been set.
  if (info.totalBytesExpectedToRead != ISCacheItemTotalBytesUnknown) {
    info.state = ISCacheItemStateInProgress;
  }
  [self notifyObservers:info];
}


- (void)itemDidFinish:(ISCacheItemInfo *)info
{
  // Update the item info with the appropriate state.
  info.state = ISCacheItemStateFound;
  [info closeFile];
  
  // TODO Use a temporary location for files being downloaded
  // and move it into permanent storage at this point.
  
  // Delete the handler for the file.
  [self.active removeObjectForKey:info.identifier];
  
  // Store the state for the completed file.
  [self.items setObject:[info dictionary]
                 forKey:info.identifier];
  [self.items writeToFile:self.path
               atomically:YES];

  // Notify our observers.
  [self notifyObservers:info];
  
  // Block delegates will delete themselves when they encounter an ISCacheItemStateFound for the
  // item. This means there is no further cleanup required here.
}


- (void)item:(ISCacheItemInfo *)info
didFailWithError:(NSError *)error
{
  [self.notifier notify:@selector(item:didFailwithError:)
             withObject:info
             withObject:error];
  
  // Remove the item.
  [self.items removeObjectForKey:info.identifier];
}


@end
