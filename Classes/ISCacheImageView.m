//
//  ISCacheImageView.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 30/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISCacheImageView.h"
#import "ISCache.h"


@interface ISCacheImageView ()

@property (strong) NSString *cacheIdentifier;

@end


@implementation ISCacheImageView


- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
  }
  return self;
}


- (void)dealloc
{
  [self cancelSetImageWithURL];
}


- (void)cancelSetImageWithURL
{
  // Cancel any outstanding load and then clear the identifier.
  if (self.cacheIdentifier) {
    ISCache *defaultCache = [ISCache defaultCache];
    if (defaultCache.debug) {
      NSLog(@"Cancel: %@", self.cacheIdentifier);
    }
    [defaultCache cancelItems:@[self.cacheIdentifier]];
    self.cacheIdentifier = nil;
  }
}


- (void)setImageWithURL:(NSString *)url
       placeholderImage:(UIImage *)placeholderImage
               userInfo:(NSDictionary *)userInfo
        completionBlock:(ISCacheCompletionBlock)completionBlock
{
  // Cancel any previous load.
  [self cancelSetImageWithURL];
  
  // Fetch the thumbnail from the cache and display it when ready.
  ISCache *defaultCache = [ISCache defaultCache];
  
  // Check the current state and clear the image if we don't
  // already have a cached copy of the image.
  ISCacheItemInfo *info
  = [defaultCache infoForItem:url
                      context:ISCacheContextScaleURL
                     userInfo:userInfo];
  if (info.state != ISCacheItemStateFound) {
    if (placeholderImage) {
      self.image = placeholderImage;
    } else {
      self.image = nil;
    }
  }
  
  // Clear the cacheIdentifier to indicate that we've just
  // set the image.
  self.cacheIdentifier = info.identifier;
  
  if (defaultCache.debug) {
    NSLog(@"Start: %@", self.cacheIdentifier);
  }
  
  // Kick-off the image download.
  ISCacheImageView *__weak weakSelf = self;
  self.cacheIdentifier = [defaultCache item:url
             context:ISCacheContextScaleURL
            userInfo:userInfo
               block:^(ISCacheItemInfo *info, NSError *error) {
                 
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
                 ISCacheImageView *strongSelf = weakSelf;
                 if (strongSelf &&
                     [strongSelf.cacheIdentifier isEqualToString:info.identifier]) {
                   
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
}


- (void)loadImageAsynchronously:(ISCacheItemInfo *)info
                completionBlock:(ISCacheCompletionBlock)completionBlock
{
  ISCacheImageView *__weak weakSelf = self;
  
  dispatch_queue_t queue =
  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    
    // First check that the image view itself is valid.
    // This gives us an oportunity to cancel loading the image
    // early if the image view has been destroyed.
    ISCacheImageView *strongSelf = weakSelf;
    if (strongSelf == nil ||
        ![strongSelf.cacheIdentifier isEqualToString:info.identifier]) {
      NSLog(@"Not attempting to load image...");
      return;
    }
    
    // Do work here.
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
    
    // Actually set the image and notify the completion block.
    dispatch_async(dispatch_get_main_queue(), ^{
      // Check that it is still valid to set the image.
      ISCacheImageView *strongSelf = weakSelf;
      if (strongSelf &&
          [strongSelf.cacheIdentifier isEqualToString:info.identifier]) {
        strongSelf.image = image;
        if (completionBlock) {
          completionBlock(nil);
        }
      }
    });
    
  });

}

@end
