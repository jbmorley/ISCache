//
//  ISHTTPCacheHandler.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 11/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheHandler.h"

@interface ISHTTPCacheHandler : NSObject <ISCacheHandler, NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@end
