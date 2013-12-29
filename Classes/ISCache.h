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
// TODO Should this function even exist?
- (ISCacheItemState)stateForItem:(NSString *)item
                         context:(NSString *)context;
- (ISCacheItemState)stateForItem:(NSString *)item
                         context:(NSString *)context
                        userInfo:(NSDictionary *)userInfo;
- (NSString *)item:(NSString *)item
           context:(NSString *)context
             block:(ISCacheBlock)completionBlock;
- (NSString *)item:(NSString *)item
           context:(NSString *)context
          userInfo:(NSDictionary *)userInfo
             block:(ISCacheBlock)completionBlock;
// TODO Provide identifier based accessors. Should these include the info at all?
- (void)removeItem:(NSString *)item
           context:(NSString *)context;
- (void)removeItem:(NSString *)item
           context:(NSString *)context
          userInfo:(NSDictionary *)userInfo;
- (void)removeItemForIdentifier:(NSString *)identifier;

- (void)addObserver:(id<ISCacheObserver>)observer;
- (void)removeObserver:(id<ISCacheObserver>)observer;


@end
