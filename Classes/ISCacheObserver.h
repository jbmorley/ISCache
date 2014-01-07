//
//  ISItemCacheObserver.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheItem.h"

@protocol ISCacheObserver <NSObject>

- (void)itemDidUpdate:(ISCacheItem *)item;

@optional
- (void)item:(ISCacheItem *)item
didFailwithError:(NSError *)error;

@end
