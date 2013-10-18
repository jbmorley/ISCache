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

@interface ISCacheObserverBlock : NSObject <ISCacheObserver>

+ (id)observerWithItem:(NSString *)item
               context:(NSString *)context
                 block:(ISCacheBlock)block;
- (id)initWithItem:(NSString *)item
           context:(NSString *)context
             block:(ISCacheBlock)block;

@end
