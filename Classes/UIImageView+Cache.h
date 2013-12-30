//
//  UIImageView+Cache.h
//  Pods
//
//  Created by Jason Barrie Morley on 12/12/2013.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ISCacheCompletionBlock.h"

@interface UIImageView (Cache)

- (void)setImageWithURL:(NSString *)url
               userInfo:(NSDictionary *)userInfo;
- (void)setImageWithURL:(NSString *)url
               userInfo:(NSDictionary *)userInfo
        completionBlock:(ISCacheCompletionBlock)completionBlock;

@end
