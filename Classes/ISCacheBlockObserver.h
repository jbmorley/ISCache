//
//  ISCacheObserverBlock.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheBlock.h"
#import "ISCacheObserver.h"

@class ISCache;

@interface ISCacheBlockObserver : NSObject <ISCacheObserver>

+ (id)observerWithItem:(ISCacheItem *)item
                 block:(ISCacheBlock)block
                 cache:(ISCache *)cache;
- (id)initWithItem:(ISCacheItem *)identifier
             block:(ISCacheBlock)block
             cache:(ISCache *)cache;

@end
