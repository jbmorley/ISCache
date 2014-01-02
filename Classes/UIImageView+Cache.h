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

- (NSString *)setImageWithURL:(NSString *)url
             placeholderImage:(UIImage *)placeholderImage
                     userInfo:(NSDictionary *)userInfo
              completionBlock:(ISCacheCompletionBlock)completionBlock;
- (void)cancelSetImageWithURL;

@end
