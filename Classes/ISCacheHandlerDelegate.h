//
//  ISCacheHandlerDelegate.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheItem.h"

@protocol ISCacheHandlerDelegate <NSObject>

- (void)itemDidUpdate:(ISCacheItem *)info;
- (void)itemDidFinish:(ISCacheItem *)info;
- (void)item:(ISCacheItem *)info
didFailWithError:(NSError *)error;

@end
