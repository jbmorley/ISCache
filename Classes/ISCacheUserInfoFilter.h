//
//  ISCacheUserInfoFilter.h
//  Pods
//
//  Created by Jason Barrie Morley on 13/02/2014.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheFilter.h"

@interface ISCacheUserInfoFilter : NSObject <ISCacheFilter>

- (id)initWithUserInfo:(NSDictionary *)userInfo;

@end
