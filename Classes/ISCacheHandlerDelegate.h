//
//  ISCacheHandlerDelegate.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheItemInfo.h"

@protocol ISCacheHandlerDelegate <NSObject>

- (void)itemDidUpdate:(ISCacheItemInfo *)info;
- (void)itemDidFinish:(ISCacheItemInfo *)info;

@end
