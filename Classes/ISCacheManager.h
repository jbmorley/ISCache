//
//  ISCacheManager.h
//  Pods
//
//  Created by Jason Barrie Morley on 13/07/2014.
//
//

#import <Foundation/Foundation.h>
#import "ISCache.h"

@class ISCacheManager;

@protocol ISCacheManagerDelegate <NSObject>

- (void)managerDidChange:(ISCacheManager *)manager;

@end

@interface ISCacheManager : NSObject
<ISCacheItemObserver>

@property (nonatomic, weak) id<ISCacheManagerDelegate> delegate;

+ (instancetype)defaultManager;
- (void)fetch:(ISCacheItem *)item;
- (void)remove:(ISCacheItem *)item;
- (NSArray *)items;

@end
