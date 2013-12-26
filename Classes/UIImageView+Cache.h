//
//  UIImageView+Cache.h
//  Pods
//
//  Created by Jason Barrie Morley on 12/12/2013.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^ISCacheCompletionBlock)(void);

@interface UIImageView (Cache)

- (void)setImageWithURL:(NSString *)url;
- (void)setImageWithURL:(NSString *)url
        completionBlock:(ISCacheCompletionBlock)completionBlock;

@end
