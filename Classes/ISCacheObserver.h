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

@end
