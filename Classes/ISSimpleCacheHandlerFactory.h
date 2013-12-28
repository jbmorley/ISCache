//
//  ISSimpleCacheHandlerFactory.h
//  Pods
//
//  Created by Jason Barrie Morley on 28/12/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheHandlerFactory.h"

@interface ISSimpleCacheHandlerFactory : NSObject
<ISCacheHandlerFactory>

+ (id)factoryWithClass:(Class)handlerClass;
- (id)initWithClass:(Class)handlerClass;

@end
