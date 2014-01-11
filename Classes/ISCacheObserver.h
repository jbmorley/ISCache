//
//  ISItemCacheObserver.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheItem.h"

@class ISCache;

@protocol ISCacheObserver <NSObject>

- (void)cache:(ISCache *)cache
itemDidUpdate:(ISCacheItem *)item;

@end
