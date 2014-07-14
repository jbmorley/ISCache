//
//  ISCacheManager.m
//  Pods
//
//  Created by Jason Barrie Morley on 13/07/2014.
//
//

#import "ISCacheManager.h"

static ISCacheManager *sCacheManager;

@interface ISCacheManager ()

@property (nonatomic, strong) NSMutableSet *cacheItems;

@property (nonatomic, strong) NSMutableSet *pending;
@property (nonatomic, strong) NSMutableSet *active;

@end

#define MAX_FETCHES 3

@implementation ISCacheManager

+ (instancetype)defaultManager
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sCacheManager = [self new];
  });
  return sCacheManager;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.cacheItems = [[NSMutableSet alloc] init];
    self.pending = [[NSMutableSet alloc] init];
    self.active = [[NSMutableSet alloc] init];
  }
  return self;
}

- (void)fetch:(ISCacheItem *)item
{
  assert([NSThread isMainThread]);
  if (item.state != ISCacheItemStateFound) {
    [self _add:item];
    [self _scheduleFetch:item];
    [self _processScheduledFetches];
    [self.delegate managerDidChange:self];
  }
}

- (void)remove:(ISCacheItem *)item
{
  assert([NSThread isMainThread]);
  [self _remove:item];
  [item remove];
  [self _processScheduledFetches];
  [self.delegate managerDidChange:self];
}

- (void)_add:(ISCacheItem *)item
{
  if (NO == [self.cacheItems containsObject:item]) {
    [self.cacheItems addObject:item];
    [item addCacheItemObserver:self options:0];
  }
}

- (void)_remove:(ISCacheItem *)item
{
  // Remove the object from the activity sets.
  [self.pending removeObject:item];
  [self.active removeObject:item];
  
  // Remove the item from the main set.
  if (YES == [self.items containsObject:item]) {
    [self.cacheItems removeObject:item];
    [item removeCacheItemObserver:self];
  }
}

- (void)_scheduleFetch:(ISCacheItem *)item
{
  // Return if a fetch is already scheduled.
  if (YES == [self.pending containsObject:item]) {
    return;
  }
  // Return if a fetch is already in progress.
  if (YES == [self.active containsObject:item]) {
    return;
  }
  // Schedule the fetch.
  [self.pending addObject:item];
}

- (void)_processScheduledFetches
{
  while ([self.pending count] > 0 &&
         [self.active count] < MAX_FETCHES) {
    ISCacheItem *item = [self.pending allObjects][0];
    [self.pending removeObject:item];
    [self.active addObject:item];
    [item fetch];
  }
}

- (NSArray *)items
{
  return [self.cacheItems allObjects];
}

#pragma mark - ISCacheItemObserver

- (void)cacheItemDidChange:(ISCacheItem *)cacheItem
{
  // Cache item changed state so we need to notify our delegate.
  assert([NSThread isMainThread]);
  
  if (cacheItem.state == ISCacheItemStateFound ||
      cacheItem.state == ISCacheItemStateNotFound) {
    [self _remove:cacheItem];
  }
  
  [self _processScheduledFetches];
  [self.delegate managerDidChange:self];
}

@end
