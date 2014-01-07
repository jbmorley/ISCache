//
//  ISCacheItemFilter.h
//  
//
//  Created by Jason Barrie Morley on 07/01/2014.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheItem.h"
#import "ISCacheFilter.h"

@interface ISCacheStateFilter : NSObject <ISCacheFilter>

+ (id)filterWithStates:(int)states;
- (id)initWithStates:(int)states;

@end
