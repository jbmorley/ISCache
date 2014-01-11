/*
 * Copyright (C) 2013-2014 InSeven Limited.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import <Foundation/Foundation.h>
#import "ISCacheHandler.h"
#import "ISCacheItem.h"
#import "ISCacheObserver.h"
#import "ISCacheBlock.h"
#import "ISCacheBlockObserver.h"
#import "ISCacheHandlerDelegate.h"
#import "ISCacheHTTPHandler.h"
#import "UIImageView+Cache.h"
#import "ISCacheHandlerFactory.h"
#import "ISScalingCacheHandlerFactory.h"
#import "ISCacheExceptions.h"
#import "ISCacheFilter.h"
#import "ISCacheStateFilter.h"

typedef enum {
  ISCacheErrorCancelled,
} ISCacheError;

static NSString *ISCacheURLContext = @"URL";
static NSString *ISCacheScaleURLContext = @"ScaleURL";
static NSString *ISCacheErrorDomain = @"ISCacheErrorDomain";

@interface ISCache : NSObject <ISCacheHandlerDelegate>

@property (nonatomic) BOOL debug;

+ (id)defaultCache;
- (id)initWithPath:(NSString *)path;

- (void)registerFactory:(id<ISCacheHandlerFactory>)factory
             forContext:(NSString *)context;

- (NSArray *)items:(id<ISCacheFilter>)filter;
- (ISCacheItem *)item:(NSString *)item
              context:(NSString *)context
             userInfo:(NSDictionary *)userInfo;
- (ISCacheItem *)fetchItem:(NSString *)item
                   context:(NSString *)context
                  userInfo:(NSDictionary *)userInfo
                     block:(ISCacheBlock)completionBlock;
- (void)removeItems:(NSArray *)items;
- (void)cancelItems:(NSArray *)items;

- (void)addObserver:(id<ISCacheObserver>)observer;
- (void)removeObserver:(id<ISCacheObserver>)observer;


@end
