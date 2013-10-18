//
//  ISCacheObserverBlock.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import "ISCacheObserverBlock.h"

@interface ISCacheObserverBlock ()

@property (nonatomic, strong) NSString *item;
@property (nonatomic, strong) NSString *context;
@property (nonatomic, strong) ISCacheBlock block;

@end

@implementation ISCacheObserverBlock

+ (id)observerWithItem:(NSString *)item
               context:(NSString *)context
                 block:(ISCacheBlock)block
{
  return [[self alloc] initWithItem:item
                            context:context
                              block:block];
}


- (id)initWithItem:(NSString *)item
           context:(NSString *)context
             block:(ISCacheBlock)block;
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
    self.block(info);
  }
  // TODO Remove ourselves when our download is finished?
}


@end
