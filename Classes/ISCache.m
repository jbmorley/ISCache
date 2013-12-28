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


// TODO Handlers need some sort of identifier which is unique
// across relaunches of the application.
// This allows us to refer to items on the file system even if the
// handlers aren't unique.

// TODO Items need to be timestamped and it should be possible to
// differentiate between permanently cached items and temporarily
// cached items.

// TODO Handlers should have an expiry strategy.

// TODO Rename handler to context
// UBUNTU:  http://mirror.bytemark.co.uk/ubuntu-releases//precise/ubuntu-12.04.2-desktop-i386.iso

// TODO Ensure delegates are correctly deleted.

// TODO Is it better if the info block contains the file handle,
// represents the mechanism for notification, etc?
// The Info could have the identifier for the file baked in which
// would make it easy to do filtered lookup, etc


@interface ISCache ()

@property (nonatomic, strong) ISNotifier *notifier;
@property (nonatomic, strong) NSMutableDictionary *factories;
@property (nonatomic, strong) NSMutableDictionary *active;
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, strong) NSMutableDictionary *info;
@property (nonatomic, strong) NSString *documentsPath;

@end

@implementation ISCache

static ISCache *sCache;


+ (id)defaultCache
{
  @synchronized (self) {
    if (sCache == nil) {
      sCache = [[self alloc] init];
    }
    return sCache;
  }
}


- (id)init
{
  self = [super init];
  if (self) {
    self.notifier = [ISNotifier new];
    self.factories = [NSMutableDictionary dictionaryWithCapacity:3];
    self.active = [NSMutableDictionary dictionaryWithCapacity:3];
    self.observers = [NSMutableArray arrayWithCapacity:3];
    self.info = [NSMutableDictionary dictionaryWithCapacity:3];
    
    self.documentsPath
    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                           NSUserDomainMask,
                                           YES) objectAtIndex:0];
    
    // Create and register the default factories.
    ISSimpleCacheHandlerFactory *httpFactory = [ISSimpleCacheHandlerFactory factoryWithClass:[ISHTTPCacheHandler class]];
    
    // Register the default handlers.
    [self registerFactory:httpFactory
               forContext:kCacheContextURL];

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


- (ISCacheItemInfo *)cacheItemInfoForItem:(NSString *)item
                                  context:(NSString *)context
{
  // Check to see if we've already created a cache item info for the
  // requested item. If we have, then return that. If not, then look
  // for the file on the file system and create an appropriate info
  // depending on whehter the file has been found or not.
  
  NSString *identifier = [self identifierForItem:item
                                         context:context];
  
  // Return a pre-existing cache item info.
  ISCacheItemInfo *info
  = [self.info objectForKey:identifier];
  if (info) {
    return info;
  }
  
  // Create a new info for the file.
  info = [ISCacheItemInfo new];
  info.item = item;
  info.context = context;
  NSString *hash = [[self identifierForItem:item
                                    context:context] MD5];
  info.path = [self.documentsPath stringByAppendingPathComponent:hash];
  [self.info setObject:info
                forKey:identifier];
  
  // Update the details if the file exists.
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:info.path
                        isDirectory:NO]) {
    info.state = ISCacheItemStateFound;
    NSError *error;
    NSDictionary *attributes
    = [fileManager attributesOfItemAtPath:info.path
                                    error:&error];
    info.totalBytesExpectedToRead
    = [[attributes valueForKey:NSFileSize] longLongValue];
    info.totalBytesRead = info.totalBytesExpectedToRead;
    
    return info;
  }
  
  // Set the details appropriately if the file doesn't exist.
  info.state = ISCacheItemStateNotFound;
  
  return info;
  
}


- (ISCacheItemState)stateForItem:(NSString *)item
                         context:(NSString *)context;
{
  ISCacheItemInfo *info = [self cacheItemInfoForItem:item
                                             context:context];
  return info.state;
}


- (void)item:(NSString *)item
     context:(NSString *)context
       block:(ISCacheBlock)completionBlock
{
  // TODO Get a user dictionary.
  NSDictionary *userInfo = nil;
  
  // Assert that we have a valid completion block.
  NSAssert(completionBlock != NULL, @"Completion block must be non-NULL.");
  
  // Get the relevant details for the item.
  NSString *identifier = [self identifierForItem:item
                                         context:context];
  ISCacheItemInfo *info = [self cacheItemInfoForItem:item
                                             context:context];
  
  if (info.state == ISCacheItemStateFound) {
    
    // If the item exists, call back with the result.
    completionBlock(info);
    
  } else if (info.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, attach a block observer.
    // TODO Consider sharing this code with the
    // other clauses.
    ISCacheObserverBlock *observer
    = [ISCacheObserverBlock observerWithItem:item
                                     context:context
                                       block:completionBlock
                                       cache:self];
    [self.observers addObject:observer];
    [self addObserver:observer];
    
  } else {
    
    // If the item doesn't exist and isn't in progress, fetch it.
    id<ISCacheHandler> handler = [self handlerForContext:context
                                                userInfo:userInfo];

    [self.active setObject:handler
                    forKey:identifier];
    
    if (completionBlock) {
      ISCacheObserverBlock *observer
      = [ISCacheObserverBlock observerWithItem:item
                                       context:context
                                         block:completionBlock
                                         cache:self];
      [self.observers addObject:observer];
      [self addObserver:observer];
    }
    
    info.state = ISCacheItemStateInProgress;
    [handler fetchItem:info
              delegate:self];
    
  }
  
}


// TODO Does this need a block observer?
- (void)removeItem:(NSString *)item
           context:(NSString *)context
{
  // Get the relevant details for the item.
  NSString *identifier = [self identifierForItem:item
                                         context:context];
  ISCacheItemInfo *info = [self cacheItemInfoForItem:item
                                             context:context];
  
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
    
    [self notifyObservers:info];
    
    // TODO Should the handler be the thing which removes
    // the file?
    
  } else if (info.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, then cancel the progress.
    // This should be sufficient to cause the cache item to be
    // removed.
    id<ISCacheHandler> handler = [self.active objectForKey:identifier];
    [handler cancel];
    
    // TODO Determine how the observers are notified in this
    // mechanism. I think it should come from the handler.
    
  } else {
    
    // If the item doesn't exist and isn't in progress, it is
    // sufficient to do nothing.
    
  }
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
}


- (void)removeObserver:(id<ISCacheObserver>)observer
{
  [self.notifier removeObserver:observer];
}


- (NSString *)identifierForItem:(NSString *)item
                        context:(NSString *)context
{
  return [NSString stringWithFormat:
          @"%@:%@",
          context,
          item];
}


// Callback handle for the handlers.
// Should not be used internally as a notification mechanism.
- (void)itemDidUpdate:(ISCacheItemInfo *)info
{
  [self notifyObservers:info];
  if (info.state == ISCacheItemStateFound) {
    // TODO Remove the item.
  }
  // TODO Remove the handler?
  // TODO Do we need to do anything about cancellation and
  // failure here?
}


- (void)itemDidFinish:(ISCacheItemInfo *)info
{
  // Update the item info with the appropriate state.
  info.state = ISCacheItemStateFound;
  [info closeFile];
  
  // Notify our observers.
  [self notifyObservers:info];
  
  // Block delegates will delete themselves when they encounter an ISCacheItemStateFound for the
  // item. This means there is no further cleanup required here.
}

@end
