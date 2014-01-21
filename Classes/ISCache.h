//
// Copyright (c) 2013 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

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
#import "ISCacheScalingHandlerFactory.h"
#import "ISCacheExceptions.h"
#import "ISCacheFilter.h"
#import "ISCacheStateFilter.h"
#import "ISCacheContextFilter.h"

typedef enum {
  ISCacheErrorCancelled,
} ISCacheError;

static NSString *ISCacheURLContext = @"URL";
static NSString *ISCacheImageContext = @"Image";
static NSString *ISCacheErrorDomain = @"ISCacheErrorDomain";

@interface ISCache : NSObject <ISCacheHandlerDelegate>

@property (nonatomic) BOOL debug;

+ (id)defaultCache;
- (id)initWithPath:(NSString *)path;

-(void)log:(NSString *)message, ...;

- (void)registerFactory:(id<ISCacheHandlerFactory>)factory
             forContext:(NSString *)context;

- (ISCacheItem *)itemForIdentifier:(NSString *)identifier
                           context:(NSString *)context
                       preferences:(NSDictionary *)preferences;
- (ISCacheItem *)fetchItemForIdentifier:(NSString *)identifier
                                context:(NSString *)context
                            preferences:(NSDictionary *)preferences
                                  block:(ISCacheBlock)completionBlock;

- (NSArray *)items:(id<ISCacheFilter>)filter;


- (void)removeItems:(NSArray *)items;
- (void)cancelItems:(NSArray *)items;

- (void)addCacheObserver:(id<ISCacheObserver>)observer;
- (void)removeCacheObserver:(id<ISCacheObserver>)observer;


@end
