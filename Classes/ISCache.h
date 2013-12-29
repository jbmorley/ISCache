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
#import "ISScalingCacheHandlerFactory.h"

typedef enum {
  ISCachePolicyStrong, // Install duration
  ISCachePolicyWeak, // Until out-of-memory
  ISCachePolicySession, // During a single running application session
  ISCachePolicyNone // Never cache
} ISCachePolicy;

static NSString *kCacheContextURL = @"URL";
static NSString *kCacheContextScaleURL = @"ScaleURL";

@interface ISCache : NSObject <ISCacheHandlerDelegate>

+ (id)defaultCache;
- (id)initWithPath:(NSString *)path;

- (void)registerFactory:(id<ISCacheHandlerFactory>)factory
             forContext:(NSString *)context;
- (ISCacheItemInfo *)infoForItem:(NSString *)item
                         context:(NSString *)context;
- (ISCacheItemInfo *)infoForItem:(NSString *)item
                         context:(NSString *)context
                        userInfo:(NSDictionary *)userInfo;
- (NSString *)item:(NSString *)item
           context:(NSString *)context
             block:(ISCacheBlock)completionBlock;
- (NSString *)item:(NSString *)item
           context:(NSString *)context
          userInfo:(NSDictionary *)userInfo
             block:(ISCacheBlock)completionBlock;
- (void)removeItemForIdentifier:(NSString *)identifier;

// TODO Rename this!
- (NSArray *)cacheItems;

- (void)addObserver:(id<ISCacheObserver>)observer;
- (void)removeObserver:(id<ISCacheObserver>)observer;


@end
