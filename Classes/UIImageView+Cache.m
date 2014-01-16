//
// Copyright (c) 2013 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "UIImageView+Cache.h"
#import "ISCache.h"
#import "ISCleanup.h"
#import <objc/runtime.h>

@implementation UIImageView (Cache)

static char *kCacheItemKey = "cacheItem";
static char *kCleanup = "cleanup";
static char *kAutomaticallyCancelsFetches = "automaticallyCancelsFetches";


- (void)cancelSetImage
{
  if (self.automaticallyCancelsFetches) {
    
    // Cancel any outstanding load and then clear the identifier.
    if (self.cacheItem) {
      ISCache *defaultCache = [ISCache defaultCache];
      if (defaultCache.debug) {
        NSLog(@"cancelSetImageWithIdentifier (%@)", self.cacheItem.uid);
      }
      [defaultCache cancelItems:@[self.cacheItem]];
      self.cacheItem = nil;
    }
  }
}


- (ISCacheItem *)setImageWithIdentifier:(NSString *)identifier
                                context:(NSString *)context
                               userInfo:(NSDictionary *)userInfo
                       placeholderImage:(UIImage *)placeholderImage
                                  block:(ISCacheBlock)block
{
  // Before proceeding, check to see if the requested item matches
  // the one we are already loading.
  ISCache *defaultCache = [ISCache defaultCache];
  ISCacheItem *item = [defaultCache itemForIdentifier:identifier
                                              context:context
                                             userInfo:userInfo];
  if ([self.cacheItem isEqual:item]) {
    
    // If the cache item does exist, then we re-set the placeholder
    // image just incase the user has requested a different one and
    // then return.
    if (placeholderImage) {
      self.image = placeholderImage;
    }
    
    return item;
  }
  
  // The requested cache item is different, so we proceed in
  // fetching the new one...
  
  // Ensure there is a cleanup object to cancel any outstanding
  // image fetches. This will be called whenever the cleanup is
  // replaced on subsequent calls to this function so will
  // magically cancel the previous fetch for us.
  UIImageView *__weak weakSelf = self;
  ISCleanup *cleanup = [ISCleanup cleanupWithBlock:^(){
    UIImageView *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf cancelSetImage];
    }
  }];
  self.cleanup = cleanup;
  
  // We always set the placeholder image as image loading is
  // performed asynchronously so may take some time to complete.
  if (placeholderImage) {
    self.image = placeholderImage;
  } else {
    self.image = nil;
  }
  
  // Store the cache item.
  self.cacheItem = item;
  
  // Logging.
  if (defaultCache.debug) {
    NSLog(@"Start: %@", item.uid);
  }
  
  // Fetch the thumbnail from the cache and display it when ready.
  ISCacheItem *cacheItem =
  [defaultCache fetchItemForIdentifier:identifier
             context:context
            userInfo:userInfo
               block:^(ISCacheItem *info) {
                 
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
                 if ([strongSelf identifierValid:info.uid]) {
                   
                   // Handle any errors.
                   // We do this inside the guarded block to ensure
                   // that, if the client has cancelled an
                   // operation or requested a new one, they never
                   // receive any further notification through
                   // the initial block.
                   if (item.lastError) {
                     if (defaultCache.debug) {
                       NSLog(@"block:%@ -> cancelled with error %@",
                             info.uid,
                             item.lastError);
                     }
                     
                     return ISCacheBlockStateDone;
                   }
                   
                   // Load the image.
                   if (info.state == ISCacheItemStateFound) {
                     if (defaultCache.debug) {
                       NSLog(@"block:%@ -> item complete",
                             info.uid);
                     }
                     [self loadImageAsynchronously:info];
                     return ISCacheBlockStateDone;
                   } else {
                     return ISCacheBlockStateContinue;
                   }
                 }
                 
                 if (defaultCache.debug) {
                   NSLog(@"block:%@ -> lost interest",
                         info.uid);
                 }
                 
                 return ISCacheBlockStateDone;
               }];
  objc_setAssociatedObject(self,
                           kCacheItemKey,
                           cacheItem,
                           OBJC_ASSOCIATION_RETAIN);
  
  // Add the block as an obsever.
  if (block) {
    ISCacheBlockObserver *observer
    = [ISCacheBlockObserver observerWithItem:cacheItem
                                       block:block];
    [defaultCache addObserver:observer];
  }
  
  return cacheItem;
}


- (BOOL)identifierValid:(NSString *)identifier
{
  @synchronized(self) {
    ISCacheItem *cacheItem = objc_getAssociatedObject(self,
                                                         kCacheItemKey);
    return [cacheItem.uid isEqualToString:identifier];
  }
}


- (void)loadImageAsynchronously:(ISCacheItem *)info
{
  UIImageView *__weak weakSelf = self;
  
  dispatch_queue_t queue =
  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    
    // First check that the image view itself is valid.
    // This gives us an oportunity to cancel loading the image
    // early if the image view has been destroyed.
    UIImageView *strongSelf = weakSelf;
    if (![strongSelf identifierValid:info.uid]) {
      return;
    }
    
    // Do work here.
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
    
    // Actually set the image and notify the completion block.
    dispatch_async(dispatch_get_main_queue(), ^{
      // Check that it is still valid to set the image.
      UIImageView *strongSelf = weakSelf;
      if ([strongSelf identifierValid:info.uid]) {
        strongSelf.image = image;
      }
    });
    
  });
  
}


- (BOOL)automaticallyCancelsFetches
{
  NSNumber *_automaticallyCancelsFetches =
  objc_getAssociatedObject(self, kAutomaticallyCancelsFetches);
  if (_automaticallyCancelsFetches) {
    return [_automaticallyCancelsFetches boolValue];
  }
  return YES;
}


- (void)setAutomaticallyCancelsFetches:(BOOL)automaticallyCancelsFetches
{
  NSNumber *_automaticallyCancelsFetches = [NSNumber numberWithBool:automaticallyCancelsFetches];
  objc_setAssociatedObject(self,
                           kAutomaticallyCancelsFetches,
                           _automaticallyCancelsFetches,
                           OBJC_ASSOCIATION_RETAIN);
}


- (ISCacheItem *)cacheItem
{
  return objc_getAssociatedObject(self, kCacheItemKey);
}


- (void)setCacheItem:(ISCacheItem *)cacheItem
{
  objc_setAssociatedObject(self,
                           kCacheItemKey,
                           cacheItem,
                           OBJC_ASSOCIATION_RETAIN);
}


- (ISCleanup *)cleanup
{
  return objc_getAssociatedObject(self, kCleanup);
}


- (void)setCleanup:(ISCleanup *)cleanup
{
  objc_setAssociatedObject(self,
                           kCleanup,
                           cleanup,
                           OBJC_ASSOCIATION_RETAIN);
}


@end
