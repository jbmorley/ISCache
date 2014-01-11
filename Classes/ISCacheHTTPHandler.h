//
//  ISHTTPCacheHandler.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 11/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheHandler.h"
#import "ISCacheBlock.h"

typedef NSError *(^ISCachePostProcessBlock)(ISCacheItem *info);

@interface ISCacheHTTPHandler : NSObject
<ISCacheHandler
,NSURLConnectionDelegate
,NSURLConnectionDataDelegate>

- (id)init;
// TODO Rename this API.
- (id)initWithCompletion:(ISCachePostProcessBlock)completionBlock;

@end
