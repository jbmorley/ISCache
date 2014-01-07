//
//  ISCacheFilter.h
//  
//
//  Created by Jason Barrie Morley on 07/01/2014.
//
//

#import <Foundation/Foundation.h>

@protocol ISCacheFilter <NSObject>

- (BOOL)matchesFilter:(ISCacheItem *)item;

@end
