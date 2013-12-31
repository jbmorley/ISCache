//
//  ISCacheObserverBlock.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import "ISCacheObserverBlock.h"
#import "ISCache.h"

@interface ISCacheObserverBlock ()

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, copy) ISCacheBlock block;
@property (nonatomic, weak) ISCache *cache;

@end

@implementation ISCacheObserverBlock

+ (id)observerWithIdentifier:(NSString *)identifier
                       block:(ISCacheBlock)block
                       cache:(ISCache *)cache
{
  return [[self alloc] initWithIdentifier:identifier
                                    block:block
                                    cache:cache];
}


- (id)initWithIdentifier:(NSString *)identifier
                   block:(ISCacheBlock)block
                   cache:(ISCache *)cache
{
  self = [super init];
  if (self) {
    self.identifier = identifier;
    self.block = block;
    self.cache = cache;
  }
  return self;
}


- (void)itemDidUpdate:(ISCacheItemInfo *)info
{
  // Ignore updates that aren't meant for us.
  if ([info.identifier isEqualToString:self.identifier]) {
    
    // Call our block.
    ISCacheBlockState result = self.block(info, nil);
    
    // Remove ourselves if the item is complete or the
    // block observer indicates that it is complete.
    if (info.state == ISCacheItemStateFound ||
        result == ISCacheBlockStateDone) {
      [self.cache removeObserver:self];
    }

  }
}


- (void)item:(ISCacheItemInfo *)info
didFailwithError:(NSError *)error
{
  self.block(info, error);
  [self.cache removeObserver:self];
}


@end
