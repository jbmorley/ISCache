//
//  ISCacheUserInfoFilter.m
//  Pods
//
//  Created by Jason Barrie Morley on 13/02/2014.
//
//

#import "ISCacheUserInfoFilter.h"

@interface ISCacheUserInfoFilter ()

@property (nonatomic, strong) NSDictionary *userInfo;

@end

@implementation ISCacheUserInfoFilter


- (id)initWithUserInfo:(NSDictionary *)userInfo
{
  self = [super init];
  if (self) {
    self.userInfo = userInfo;
  }
  return self;
}


- (BOOL)matchesFilter:(ISCacheItem *)item
{
  __block BOOL matches = YES;
  [self.userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    matches = [obj isEqual:item.userInfo[key]];
    if (!matches) {
      *stop = YES;
    }
  }];
  return matches;
}


@end
