//
//  ISItemCacheObserver.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheItemInfo.h"

@protocol ISCacheObserver <NSObject>

- (void)itemDidUpdate:(ISCacheItemInfo *)info;

// TODO How do we differentiate between progress unknown and progress
// known (to support download mechanims which don't know progress...)

@end
