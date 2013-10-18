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
@property (nonatomic, strong) NSMutableDictionary *handlers;
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
    self.handlers = [NSMutableDictionary dictionaryWithCapacity:3];
    self.active = [NSMutableDictionary dictionaryWithCapacity:3];
    self.observers = [NSMutableArray arrayWithCapacity:3];
    self.info = [NSMutableDictionary dictionaryWithCapacity:3];
    
    self.documentsPath
    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                           NSUserDomainMask,
                                           YES) objectAtIndex:0];
  }
  return self;
}


- (void)registerClass:(Class)handlerClass
           forContext:(NSString *)context
{
  // Check the class conforms to the correct protocol.
  if (![handlerClass conformsToProtocol:@protocol(ISCacheHandler)]) {
    @throw [NSException exceptionWithName:@"InvalidHandlerClass"
                                   reason:@"Cache handlers must respond to the NSCacheHandler protocol."
                                 userInfo:nil];
  }
  
  // Check that there isn't an existing handler for that context.
  if ([self.handlers objectForKey:context] != nil) {
    @throw [NSException exceptionWithName:@"HandlerRegistered"
                                   reason:@"A cache handler has already been registered for the specified protocol."
                                 userInfo:nil];
  }
  
  // Register the handler.
  [self.handlers setObject:handlerClass
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
  NSLog(@"info.path %@", info.path);
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
  // Check there is a handler registered for the context.
  Class handlerClass = [self.handlers objectForKey:context];
  if (handlerClass == nil) {
    @throw [NSException exceptionWithName:@"MissingHandler"
                                   reason:@"No cache handler has been registered for the specified protocol."
                                 userInfo:nil];
  }
  
  // Get the identifier for the item.
  
  NSString *identifier = [self identifierForItem:item
                                         context:context];
  ISCacheItemInfo *info = [self cacheItemInfoForItem:item
                                             context:context];
  
  if (info.state == ISCacheItemStateFound) {
    
    // If the item exists, call back with the result.
    NSLog(@"Item exists in cache");
    completionBlock(info);
    
  } else if (info.state == ISCacheItemStateInProgress) {
    
    // If the item is in progress, attach a block observer.
    NSLog(@"Observing pending fetch...");
    ISCacheObserverBlock *observer
    = [ISCacheObserverBlock observerWithItem:item
                                     context:context
                                       block:completionBlock];
    [self.observers addObject:observer];
    [self addObserver:observer];
    
  } else {
    
    // If the item doesn't exist and isn't in progress, fetch it.
    NSLog(@"Initiating new fetch...");
    id<ISCacheHandler> handler = [[handlerClass alloc] init];
    [self.active setObject:handler
                    forKey:identifier];
    ISCacheObserverBlock *observer
    = [ISCacheObserverBlock observerWithItem:item
                                     context:context
                                       block:completionBlock];
    [self.observers addObject:observer];
    [self addObserver:observer];
    [handler fetchItem:info
              delegate:self];
    
  }
  
}


- (void)addObserver:(id<ISCacheObserver>)observer
{
  [self.notifier addObserver:observer];
}


- (void)remvoveObserver:(id<ISCacheObserver>)observer
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


- (void)itemDidUpdate:(ISCacheItemInfo *)info;
{
  [self.notifier notify:@selector(itemDidUpdate:)
             withObject:info];
  if (info.state == ISCacheItemStateFound) {
    // TODO Remove the item.
  }
}

@end
