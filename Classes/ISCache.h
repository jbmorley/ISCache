//
//  ISCache.h
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

typedef enum {
  ISCacheErrorCancelled,
} ISCacheError;

static NSString *ISCacheContextURL = @"URL";
static NSString *ISCacheContextScaleURL = @"ScaleURL";
static NSString *ISCacheErrorDomain = @"ISCacheErrorDomain";

@interface ISCache : NSObject <ISCacheHandlerDelegate>

@property (nonatomic) BOOL debug;

+ (id)defaultCache;
- (id)initWithPath:(NSString *)path;

- (void)registerFactory:(id<ISCacheHandlerFactory>)factory
             forContext:(NSString *)context;
- (ISCacheItemInfo *)infoForItem:(NSString *)item
                         context:(NSString *)context
                        userInfo:(NSDictionary *)userInfo;
- (NSString *)item:(NSString *)item
           context:(NSString *)context
          userInfo:(NSDictionary *)userInfo
             block:(ISCacheBlock)completionBlock;

- (NSArray *)identifiers:(int)filter;
- (void)removeItems:(NSArray *)identifiers;
- (void)cancelItems:(NSArray *)identifier;

- (void)addObserver:(id<ISCacheObserver>)observer;
- (void)removeObserver:(id<ISCacheObserver>)observer;


@end
