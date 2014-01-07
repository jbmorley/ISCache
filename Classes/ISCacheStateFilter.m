//
//  ISCacheItemFilter.m
//  
//
//  Created by Jason Barrie Morley on 07/01/2014.
//
//

#import "ISCacheStateFilter.h"


@interface ISCacheStateFilter ()

@property (nonatomic) int states;

@end



@implementation ISCacheStateFilter

+ (id)filterWithStates:(int)states
{
  return [[self alloc] initWithStates:states];
}


- (id)initWithStates:(int)states
{
  self = [super init];
  if (self) {
    self.states = states;
  }
  return self;
}


- (BOOL)matchesFilter:(ISCacheItem *)item
{
  return ((item.state & self.states) > 0);
}


@end
