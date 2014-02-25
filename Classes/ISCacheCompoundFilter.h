//
//  ISCacheCompoundFilter.h
//  Pods
//
//  Created by Jason Barrie Morley on 25/02/2014.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheFilter.h"

@interface ISCacheCompoundFilter : NSObject <ISCacheFilter>

+ (id)filterMatching:(id<ISCacheFilter>)filterA
                 and:(id<ISCacheFilter>)filterB;
+ (id)filterMatching:(id<ISCacheFilter>)filterA
                  or:(id<ISCacheFilter>)filterB;

- (id)initMatching:(id<ISCacheFilter>)filterA
               and:(id<ISCacheFilter>)filterB;
- (id)initMatching:(id<ISCacheFilter>)filterA
                or:(id<ISCacheFilter>)filterB;

- (ISCacheCompoundFilter *)and:(id<ISCacheFilter>)filter;
- (ISCacheCompoundFilter *)or:(id<ISCacheFilter>)filter;


@end
