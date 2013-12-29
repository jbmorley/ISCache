//
//  ISScalingCacheHandlerFactory.h
//  
//
//  Created by Jason Barrie Morley on 29/12/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheHandlerFactory.h"

typedef enum {
  ISScalingCacheHandlerScaleAspectFit,
  ISScalingCacheHandlerScaleAspectFill,
} ISScalingCacheHandlerScale;

@interface ISScalingCacheHandlerFactory : NSObject
<ISCacheHandlerFactory>

@end
