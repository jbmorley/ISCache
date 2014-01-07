//
//  UIImageView+Cache.m
//  Pods
//
//  Created by Jason Barrie Morley on 12/12/2013.
//
//

#import "UIImageView+Cache.h"
#import "ISCache.h"
#import "ISCleanup.h"
#import <objc/runtime.h>

@implementation UIImageView (Cache)

static char *kCacheItemKey = "cacheItem";
static char *kCleanupIdentifier = "cleanup";


- (void)cancelSetImageWithURL
{
  ISCacheItem *cacheItem = objc_getAssociatedObject(self, kCacheItemKey);
  
  // Cancel any outstanding load and then clear the identifier.
  if (cacheItem) {
    ISCache *defaultCache = [ISCache defaultCache];
    if (defaultCache.debug) {
      NSLog(@"Cancel: %@", cacheItem.identifier);
    }
    [defaultCache cancelItems:@[cacheItem]];
    objc_setAssociatedObject(self,
                             kCacheItemKey,
                             nil,
                             OBJC_ASSOCIATION_RETAIN);
  }
}


- (ISCacheItem *)setImageWithURL:(NSString *)url
                placeholderImage:(UIImage *)placeholderImage
                        userInfo:(NSDictionary *)userInfo
                 completionBlock:(ISCacheCompletionBlock)completionBlock
{
  // Ensure there is a cleanup object to cancel any outstanding
  // image fetches. This will be called whenever the cleanup is
  // replaced on subsequent calls to this function so will
  // magically cancel the previous fetch for us.
  UIImageView *__weak weakSelf = self;
  
  ISCleanup *cleanup = [ISCleanup cleanupWithBlock:^(){
    UIImageView *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf cancelSetImageWithURL];
    }
  }];
  objc_setAssociatedObject(self,
                           kCleanupIdentifier,
                           cleanup,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
  // Fetch the thumbnail from the cache and display it when ready.
  ISCache *defaultCache = [ISCache defaultCache];
  
  // Check the current state and clear the image if we don't
  // already have a cached copy of the image.
  ISCacheItem *item
  = [defaultCache item:url
                      context:ISCacheContextScaleURL
                     userInfo:userInfo];
  if (placeholderImage) {
    self.image = placeholderImage;
  } else {
    self.image = nil;
  }
  
  // Clear the cacheIdentifier to indicate that we've just
  // set the image.
  objc_setAssociatedObject(self,
                           kCacheItemKey,
                           item,
                           OBJC_ASSOCIATION_RETAIN);
  
  if (defaultCache.debug) {
    NSLog(@"Start: %@", item.identifier);
  }
  
  // Kick-off the image download.
  ISCacheItem *cacheItem =
  [defaultCache fetchItem:url
             context:ISCacheContextScaleURL
            userInfo:userInfo
               block:^(ISCacheItem *info, NSError *error) {
                 
                 // Check that the image view is valid and the
                 // identifier we are receiving updates for matches
                 // the one requested. This might occur if image
                 // view is reused for a different image (e.g.
                 // UITableViewCell, UICollectionViewCell, etc.
                 // The special case here is that the first
                 // response from the cache is received before
                 // we have returned from the item:context:... call
                 // so we need to guard against this by checking
                 // for a nil cacheIdentifier.
                 UIImageView *strongSelf = weakSelf;
                 if ([strongSelf identifierValid:info.identifier]) {
                   
                   // Handle any errors.
                   // We do this inside the guarded block to ensure
                   // that, if the client has cancelled an
                   // operation or requested a new one, they never
                   // receive any further notification through
                   // the initial block.
                   if (error != nil) {
                     if (defaultCache.debug) {
                       NSLog(@"block:%@ -> cancelled with error %@",
                             info.identifier,
                             error);
                     }
                     
                     if (completionBlock) {
                       completionBlock(error);
                     }
                     return ISCacheBlockStateDone;
                   }
                   
                   // Load the image.
                   if (info.state == ISCacheItemStateFound) {
                     if (defaultCache.debug) {
                       NSLog(@"block:%@ -> item complete",
                             info.identifier);
                     }
                     [self loadImageAsynchronously:info
                                   completionBlock:completionBlock];
                     return ISCacheBlockStateDone;
                   } else {
                     return ISCacheBlockStateContinue;
                   }
                 }
                 
                 if (defaultCache.debug) {
                   NSLog(@"block:%@ -> lost interest",
                         info.identifier);
                 }
                 
                 return ISCacheBlockStateDone;
               }];
  objc_setAssociatedObject(self,
                           kCacheItemKey,
                           cacheItem,
                           OBJC_ASSOCIATION_RETAIN);
  
  return cacheItem;
}


- (BOOL)identifierValid:(NSString *)identifier
{
  @synchronized(self) {
    ISCacheItem *cacheItem = objc_getAssociatedObject(self,
                                                         kCacheItemKey);
    return [cacheItem.identifier isEqualToString:identifier];
  }
}


- (void)loadImageAsynchronously:(ISCacheItem *)info
                completionBlock:(ISCacheCompletionBlock)completionBlock
{
  UIImageView *__weak weakSelf = self;
  
  dispatch_queue_t queue =
  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    
    // First check that the image view itself is valid.
    // This gives us an oportunity to cancel loading the image
    // early if the image view has been destroyed.
    UIImageView *strongSelf = weakSelf;
    if (![strongSelf identifierValid:info.identifier]) {
      return;
    }
    
    // Do work here.
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
    
    // Actually set the image and notify the completion block.
    dispatch_async(dispatch_get_main_queue(), ^{
      // Check that it is still valid to set the image.
      UIImageView *strongSelf = weakSelf;
      if ([strongSelf identifierValid:info.identifier]) {
        strongSelf.image = image;
        if (completionBlock) {
          completionBlock(nil);
        }
      }
    });
    
  });
  
}


@end
