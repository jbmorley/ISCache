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
@property (nonatomic, strong) ISCacheBlock block;
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
  }
  return self;
}


- (void)itemDidUpdate:(ISCacheItemInfo *)info
{
  // Ignore updates that aren't meant for us.
  if ([info.identifier isEqualToString:self.identifier]) {
        
    // Call our block.
    self.block(info);
        
    // Remove ourselves if the item is complete.
    if (info.state == ISCacheItemStateFound) {
      [self.cache removeObserver:self];
    }

  }
}


@end
