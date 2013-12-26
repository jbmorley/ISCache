//
//  UIImageView+Cache.m
//  Pods
//
//  Created by Jason Barrie Morley on 12/12/2013.
//
//

#import "UIImageView+Cache.h"
#import "ISCache.h"

@implementation UIImageView (Cache)

- (void)setImageWithURL:(NSString *)url
{
  [self setImageWithURL:url
        completionBlock:^{}];
}

- (void)setImageWithURL:(NSString *)url
        completionBlock:(ISCacheCompletionBlock)completionBlock
{
  // Fetch the thumbnail from the cache and display it when ready.
  ISCache *defaultCache = [ISCache defaultCache];
  
  // Check the current state and clear the image if we don't
  // already have a cached copy of the image.
  ISCacheItemState state
  = [defaultCache stateForItem:url
                       context:kCacheContextURL];
  if (state != ISCacheItemStateFound) {
    self.image = nil;
  }
  
  // Kick-off the image download.
  [defaultCache item:url
             context:kCacheContextURL
               block:^(ISCacheItemInfo *info) {
                 if (info.state == ISCacheItemStateFound) {
                   self.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
                   completionBlock();
                 }
               }];
}

@end
