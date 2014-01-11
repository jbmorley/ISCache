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

@end

@implementation ISCacheBlockObserver

+ (id)observerWithItem:(ISCacheItem *)item
                 block:(ISCacheBlock)block
{
  return [[self alloc] initWithItem:item
                              block:block];
}


- (id)initWithItem:(ISCacheItem *)item
             block:(ISCacheBlock)block
{
  self = [super init];
  if (self) {
    self.identifier = item.identifier;
    self.block = block;
  }
  return self;
}


- (void)cache:(ISCache *)cache
itemDidUpdate:(ISCacheItem *)item
{
  // Ignore updates that aren't meant for us.
  if ([item.identifier isEqualToString:self.identifier]) {
    
    // Call our block.
    ISCacheBlockState result = self.block(item);
    
    // Remove ourselves if the item is complete, if the
    // block observer indicates that it is complete, or if
    // we have encountered an error.
    // While strictly lastError should only ever be set if the
    // state is ISCacheItemStateNotFound, it is safer to always
    // check for a non-nil lastError.
    if (item.state == ISCacheItemStateFound ||
        result == ISCacheBlockStateDone ||
        item.lastError) {
      [cache removeObserver:self];
    }
  }
}


@end
