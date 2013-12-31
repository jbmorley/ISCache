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
        completionBlock:^{}];
}


- (void)setImageWithURL:(NSString *)url
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
    self.image = nil;
  }
  
  self.cacheIdentifier = info.identifier;
  
  // Kick-off the image download.
  UIImageView *__weak weakSelf = self;
  [defaultCache item:url
             context:kCacheContextScaleURL
            userInfo:userInfo
               block:^(ISCacheItemInfo *info) {
                 UIImageView *strongSelf = weakSelf;
                 if (strongSelf) {
                   if (info.state == ISCacheItemStateFound) {
                     self.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
                     completionBlock();
                   }
                   return ISCacheBlockStateContinue;
                 }
                 return ISCacheBlockStateDone;
               }
               error:^(ISCacheItemInfo *info, NSError *error) {
                 // TODO We should indicate failure somehow.
                 completionBlock();
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
