//
//  ISCacheCompoundFilter.m
//  Pods
//
//  Created by Jason Barrie Morley on 25/02/2014.
//
//

#import "ISCacheCompoundFilter.h"

typedef enum {
  ISCacheCompoundFilterModeAND,
  ISCacheCompoundFilterModeOR,
} ISCacheCompoundFilterMode;

@interface ISCacheCompoundFilter ()

@property (nonatomic, strong) id<ISCacheFilter> filterA;
@property (nonatomic, strong) id<ISCacheFilter> filterB;
@property (nonatomic, assign) ISCacheCompoundFilterMode mode;

@end

@implementation ISCacheCompoundFilter

+ (id)filterMatching:(id<ISCacheFilter>)filterA
                 and:(id<ISCacheFilter>)filterB
{
  return [[self alloc] initMatching:filterA
                                and:filterB];
}

+ (id)filterMatching:(id<ISCacheFilter>)filterA
                  or:(id<ISCacheFilter>)filterB
{
  return [[self alloc] initMatching:filterA
                                 or:filterB];
}

- (id)initMatching:(id<ISCacheFilter>)filterA
               and:(id<ISCacheFilter>)filterB
{
  self = [super init];
  if (self) {
    self.mode = ISCacheCompoundFilterModeAND;
    self.filterA = filterA;
    self.filterB = filterB;
  }
  return self;
}

- (id)initMatching:(id<ISCacheFilter>)filterA
                or:(id<ISCacheFilter>)filterB
{
  self = [super init];
  if (self) {
    self.mode = ISCacheCompoundFilterModeOR;
    self.filterA = filterA;
    self.filterB = filterB;
  }
  return self;
}

- (BOOL)matchesFilter:(ISCacheItem *)item
{
  if (self.mode == ISCacheCompoundFilterModeAND) {
    return ([self.filterA matchesFilter:item] &&
            [self.filterB matchesFilter:item]);
  } else if (self.mode == ISCacheCompoundFilterModeOR) {
    return ([self.filterA matchesFilter:item] ||
            [self.filterB matchesFilter:item]);
  }
  return NO;
}

- (ISCacheCompoundFilter *)and:(id<ISCacheFilter>)filter
{
  return [ISCacheCompoundFilter filterMatching:self
                                           and:filter];
}


- (ISCacheCompoundFilter *)or:(id<ISCacheFilter>)filter
{
  return [ISCacheCompoundFilter filterMatching:self
                                            or:filter];
}

@end
