//
//  ISCacheStore.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 03/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISCacheItemInfo.h"

@interface ISCacheStore : NSObject

+ (id)storeWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;
- (void)save;

- (ISCacheItemInfo *)item:(NSString *)identifier;
- (NSArray *)items:(int)states;
- (void)addItem:(ISCacheItemInfo *)item;
- (void)removeItem:(ISCacheItemInfo *)item;


@end
