//
//  ISItemCache.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 28/07/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheHandler.h"
#import "ISCacheItemInfo.h"
#import "ISCacheObserver.h"
#import "ISCacheBlock.h"
#import "ISCacheHandlerDelegate.h"
#import "ISHTTPCacheHandler.h"
#import "UIImageView+Cache.h"
#import "ISCacheHandlerFactory.h"

typedef enum {
  ISCachePolicyStrong, // Install duration
  ISCachePolicyWeak, // Until out-of-memory
  ISCachePolicySession, // During a single running application session
  ISCachePolicyNone // Never cache
} ISCachePolicy;

static NSString *kCacheContextURL = @"URL";

@interface ISCache : NSObject <ISCacheHandlerDelegate>

+ (id)defaultCache;

- (void)registerClass:(Class)handlerClass
           forContext:(NSString *)context;
- (void)registerFactory:(id<ISCacheHandlerFactory>)factory
             forContext:(NSString *)context;
- (ISCacheItemState)stateForItem:(NSString *)item
                         context:(NSString *)context;
- (void)item:(NSString *)item
     context:(NSString *)context
       block:(ISCacheBlock)completionBlock;
- (void)removeItem:(NSString *)item
           context:(NSString *)context;

- (void)addObserver:(id<ISCacheObserver>)observer;
- (void)removeObserver:(id<ISCacheObserver>)observer;


@end
