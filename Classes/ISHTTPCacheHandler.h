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

@interface ISHTTPCacheHandler : NSObject
<ISCacheHandler
,NSURLConnectionDelegate
,NSURLConnectionDataDelegate>

- (id)init;
- (id)initWithCompletion:(ISCacheBlock)completionBlock;

@end
