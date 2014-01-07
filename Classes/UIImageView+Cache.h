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
#import "ISCacheItem.h"

@interface UIImageView (Cache)

- (ISCacheItem *)setImageWithURL:(NSString *)url
                placeholderImage:(UIImage *)placeholderImage
                        userInfo:(NSDictionary *)userInfo
                 completionBlock:(ISCacheCompletionBlock)completionBlock;
- (void)cancelSetImageWithURL;

@end
