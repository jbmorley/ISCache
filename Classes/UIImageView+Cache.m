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
static char *kCallbackCount = "callbackCount";


- (void)cancelSetImage
{
  if (self.automaticallyCancelsFetches) {
    
    // Cancel any outstanding load and then clear the identifier.
    if (self.cacheItem) {
      ISCache *defaultCache = [ISCache defaultCache];
      [defaultCache log:
       @"cancelSetImageWithIdentifier (%@)",
       self.cacheItem.uid];
      [defaultCache cancelItems:@[self.cacheItem]];
      self.cacheItem = nil;
      self.callbackCount++;
    }
  }
}


- (ISCacheItem *)setImageWithIdentifier:(NSString *)identifier
                                context:(NSString *)context
                            preferences:(NSDictionary *)preferences
                       placeholderImage:(UIImage *)placeholderImage
                                  block:(ISCacheBlock)block
{
  ISCache *defaultCache = [ISCache defaultCache];
  
  // Logging.
  [defaultCache log:
   @"setImageWithIdentifier:%@ context:%@",
   identifier,
   context];
  
  // Before proceeding, check to see if the requested item matches
  // the one we are already loading.
  ISCacheItem *item = [defaultCache itemForIdentifier:identifier
                                              context:context
                                          preferences:preferences];
  
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
  [defaultCache log:@"Start: %@", item.uid];
  
  
  // Increment the callback count to indicate that we are requesting a new image.
  self.callbackCount++;
  
  NSInteger callback = self.callbackCount;
  
  // Fetch the thumbnail from the cache and display it when ready.
  [defaultCache fetchItemForIdentifier:identifier
             context:context
            preferences:preferences
               block:^(ISCacheItem *info) {
                 
                 // If the image has been deleted or the callback is now
                 // obsolete, simply return, expressing our lack of interest.
                 UIImageView *strongSelf = weakSelf;
                 if (strongSelf == nil ||
                     strongSelf.callbackCount != callback) {
                   
                   [defaultCache log:
                    @"block:%@ -> lost interest",
                    info.uid];
                   
                   return ISCacheBlockStateDone;
                 }
                 
                 // Log any errors that are encountered.
                 // Erros are fatal so it is OK to give up here.
                 if (item.lastError) {
                   [defaultCache log:
                    @"block:%@ -> cancelled with error %@",
                    info.uid,
                    item.lastError];
                   return ISCacheBlockStateDone;
                 }
                 
                 // Load the image if we are complete.
                 if (info.state == ISCacheItemStateFound) {
                   [defaultCache log:
                    @"block:%@ -> item complete",
                    info.uid];
                   [self loadImageAsynchronously:info
                                        callback:callback];
                   return ISCacheBlockStateDone;
                 }
                 
                 // Request further updates.
                 return ISCacheBlockStateContinue;
               }];
  
  // Add the block as an obsever.
  // We wrap this with a block to ensure the same cancellation semtantics
  // as the image itself. We want to guarantee that no updates are received
  // once the image has been changed or cancelled.
  if (block) {
    ISCacheBlockObserver *observer
    = [ISCacheBlockObserver observerWithItem:item
                                       block:^ISCacheBlockState(ISCacheItem *info) {
                                         
                                         UIImageView *strongSelf = weakSelf;
                                         if (strongSelf == nil ||
                                             strongSelf.callbackCount != callback) {
                                           return ISCacheBlockStateDone;
                                         }
                                         
                                         return block(info);
                                         
                                       }];
    [defaultCache addCacheObserver:observer];
  }
  
  return item;
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
                       callback:(NSInteger)callback
{
  UIImageView *__weak weakSelf = self;
  
  dispatch_queue_t queue =
  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
  dispatch_async(queue, ^{
    
    // Do the work here.
    UIImage *image =
    [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
    
    // Actually set the image and notify the completion block.
    dispatch_async(dispatch_get_main_queue(), ^{
      
      // Check that it is still valid to set the image.
      UIImageView *strongSelf = weakSelf;
      if (strongSelf == nil ||
          strongSelf.callbackCount != callback) {
        return;
      }

      strongSelf.image = image;
      
      [self.cleanup cancel];
    });
    
  });
  
}


#pragma mark - Getters and setters


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


- (void)setCallbackCount:(NSInteger)callbackCount
{
  objc_setAssociatedObject(self,
                           kCallbackCount,
                           [NSNumber numberWithInteger:callbackCount], OBJC_ASSOCIATION_RETAIN);
}


- (NSInteger)callbackCount
{
  NSNumber *callbackCount = objc_getAssociatedObject(self,
                                                     kCallbackCount);
  if (callbackCount) {
    return [callbackCount integerValue];
  }
  return 0;
}

@end
