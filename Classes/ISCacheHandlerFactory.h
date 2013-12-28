//
//  ISCacheHandlerFactory.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 28/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISCacheHandler.h"

@protocol ISCacheHandlerFactory <NSObject>

// Ownership is passed to the callee.
- (id<ISCacheHandler>)createHandler:(NSDictionary *)userInfo;

@end
