//
//  ISCacheStore.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 03/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISCacheItem.h"
#import "ISCacheFilter.h"

@interface ISCacheStore : NSObject

+ (id)storeWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;
- (void)save;

- (ISCacheItem *)item:(NSString *)identifier;
- (NSArray *)items:(id <ISCacheFilter>)filter;
- (void)addItem:(ISCacheItem *)item;
- (void)removeItem:(ISCacheItem *)item;


@end
