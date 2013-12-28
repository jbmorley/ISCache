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

@property (nonatomic, strong) NSString *item;
@property (nonatomic, strong) NSString *context;
@property (nonatomic, strong) ISCacheBlock block;
@property (nonatomic, weak) ISCache *cache;

@end

@implementation ISCacheObserverBlock

+ (id)observerWithItem:(NSString *)item
               context:(NSString *)context
                 block:(ISCacheBlock)block
                 cache:(ISCache *)cache
{
  return [[self alloc] initWithItem:item
                            context:context
                              block:block
                              cache:cache];
}


- (id)initWithItem:(NSString *)item
           context:(NSString *)context
             block:(ISCacheBlock)block
             cache:(ISCache *)cache;
{
  self = [super init];
  if (self) {
    self.item = item;
    self.context = context;
    self.block = block;
  }
  return self;
}


- (void)itemDidUpdate:(ISCacheItemInfo *)info
{
  // Ignore updates that aren't meant for us.
  if ((self.item == nil ||
       [info.item isEqualToString:self.item]) &&
      (self.context == nil ||
       [info.context isEqualToString:self.context])) {
        
    // Call our block.
    self.block(info);
        
    // Remove ourselves if the item is complete.
    if (info.state == ISCacheItemStateFound) {
      [self.cache removeObserver:self];
    }

  }
}


@end
