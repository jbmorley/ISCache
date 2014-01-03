//
//  ISCacheHandler.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheHandlerDelegate.h"

@protocol ISCacheHandler <NSObject>

- (void)fetchItem:(ISCacheItem *)info
         delegate:(id<ISCacheHandlerDelegate>)delegate;
- (void)cancel;

@end
