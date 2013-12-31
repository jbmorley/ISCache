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

@interface ISCacheObserverBlock : NSObject <ISCacheObserver>

+ (id)observerWithIdentifier:(NSString *)item
                       block:(ISCacheBlock)block
                       cache:(ISCache *)cache;
- (id)initWithIdentifier:(NSString *)identifier
                   block:(ISCacheBlock)block
                   cache:(ISCache *)cache;

@end
