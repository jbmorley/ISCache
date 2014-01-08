//
//  ISCacheObserverBlock.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import "ISCacheBlockObserver.h"
#import "ISCache.h"

@interface ISCacheBlockObserver ()

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, copy) ISCacheBlock block;
@property (nonatomic, weak) ISCache *cache;

@end

@implementation ISCacheBlockObserver

+ (id)observerWithItem:(ISCacheItem *)item
                 block:(ISCacheBlock)block
                 cache:(ISCache *)cache
{
  return [[self alloc] initWithItem:item
                              block:block
                              cache:cache];
}


- (id)initWithItem:(ISCacheItem *)item
             block:(ISCacheBlock)block
             cache:(ISCache *)cache
{
  self = [super init];
  if (self) {
    self.identifier = item.identifier;
    self.block = block;
    self.cache = cache;
  }
  return self;
}


- (void)cache:(ISCache *)cache
itemDidUpdate:(ISCacheItem *)item
{
  // Ignore updates that aren't meant for us.
  if ([item.identifier isEqualToString:self.identifier]) {
    
    // Call our block.
    ISCacheBlockState result = self.block(item, nil);
    
    // Remove ourselves if the item is complete or the
    // block observer indicates that it is complete.
    if (item.state == ISCacheItemStateFound ||
        result == ISCacheBlockStateDone) {
      [cache removeObserver:self];
    }

  }
}


- (void)cache:(ISCache *)cache
         item:(ISCacheItem *)item
didFailwithError:(NSError *)error
{
  // Ignore updates that aren't meant for us.
  if ([item.identifier isEqualToString:self.identifier]) {
    self.block(item, error);
    [cache removeObserver:self];
  }
}


@end
