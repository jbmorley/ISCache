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

@property (nonatomic, strong) NSString *cacheIdentifier;

@end


@implementation ISCacheImageView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    ISCache *defaultCache = [ISCache defaultCache];
    [defaultCache addObserver:self];
  }
  return self;
}


- (void)awakeFromNib
{
  [super awakeFromNib];
  ISCache *defaultCache = [ISCache defaultCache];
  [defaultCache addObserver:self];
}


- (void)dealloc
{
  ISCache *defaultCache = [ISCache defaultCache];
  [defaultCache removeObserver:self];
}


- (void)setImageWithURL:(NSString *)url
               userInfo:(NSDictionary *)userInfo
{
  [self setImageWithURL:url
               userInfo:userInfo
        completionBlock:NULL];
}


- (void)setImageWithURL:(NSString *)url
       placeholderImage:(UIImage *)placeholderImage
               userInfo:(NSDictionary *)userInfo
        completionBlock:(ISCacheCompletionBlock)completionBlock
{
  // Fetch the thumbnail from the cache and display it when ready.
  ISCache *defaultCache = [ISCache defaultCache];
  
  // Check the current state and clear the image if we don't
  // already have a cached copy of the image.
  ISCacheItemInfo *info
  = [defaultCache infoForItem:url
                      context:kCacheContextURL
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
  self.cacheIdentifier = nil;
  
  // TODO Work out why setting the cache identifier from the info
  // here doesn't work?
  
  // Kick-off the image download.
  ISCacheImageView *__weak weakSelf = self;
  self.cacheIdentifier = [defaultCache item:url
             context:kCacheContextScaleURL
            userInfo:userInfo
               block:^(ISCacheItemInfo *info, NSError *error) {
                 if (error != nil) {
                   if (completionBlock) {
                     completionBlock(error);
                   }
                   return ISCacheBlockStateDone;
                 }
                 
                 ISCacheImageView *strongSelf = weakSelf;
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
                 if (strongSelf &&
                     (strongSelf.cacheIdentifier == nil ||
                      [strongSelf.cacheIdentifier isEqualToString:info.identifier])) {
                   if (info.state == ISCacheItemStateFound) {
                     self.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
                     if (completionBlock) {
                       completionBlock(nil);
                     }
                   }
                   return ISCacheBlockStateContinue;
                 }
                 return ISCacheBlockStateDone;
               }];
}


- (void)itemDidUpdate:(ISCacheItemInfo *)info
{
  if ([info.identifier isEqualToString:self.cacheIdentifier] &&
      info.state == ISCacheItemStateNotFound) {
    NSLog(@"Item no longer in cache.");
  }
}


@end
