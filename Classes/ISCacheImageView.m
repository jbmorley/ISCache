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

#import "ISCacheImageView.h"
#import "ISCache.h"
#import "ISCleanup.h"
#import <objc/runtime.h>


@interface ISCacheImageView ()

@property (nonatomic, strong) ISCacheItem *cacheItem;
@property (nonatomic) NSInteger callbackCount;

@end


@implementation ISCacheImageView


- (void)cancelSetImage
{
  NSLog(@"cancelSetImage");
  [self stopObservingCacheItem];
  if (self.automaticallyCancelsFetches) {
    [self.cacheItem cancel];
  }
  self.cacheItem = nil;
  self.callbackCount++;
}


- (void)dealloc
{
  [self cancelSetImage];
}


- (ISCacheItem *)setImageWithIdentifier:(NSString *)identifier
                                context:(NSString *)context
                            preferences:(NSDictionary *)preferences
                       placeholderImage:(UIImage *)placeholderImage
                                  block:(ISCacheBlock)block
{
  ISCache *defaultCache = [ISCache defaultCache];
  
  // Cancel the previous fetch.
  // TODO Compare the images and only cancel if they're
  // different.
  [self cancelSetImage];
  
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
  
  // We always set the placeholder image as image loading is
  // performed asynchronously so may take some time to complete.
  if (placeholderImage) {
    self.image = placeholderImage;
  } else {
    self.image = nil;
  }
  
  // Increment the callback count.
  self.callbackCount++;
  
  // Store the cache item and observe it.
  self.cacheItem = item;
  [self startObservingCacheItem];
  
  // Logging.
  [defaultCache log:@"Start: %@", item.uid];
  
  // Fetch the item if neccessary.
  if (self.cacheItem.state == ISCacheItemStateNotFound) {
    [self.cacheItem fetch];
  }
  
  return item;
}


- (void)loadImageAsynchronously:(NSInteger)callback
{
  ISCacheImageView *__weak weakSelf = self;
  ISCacheItem *cacheItem = self.cacheItem;
  
  dispatch_queue_t queue =
  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    
    // Do the work here.
    UIImage *image =
    [UIImage imageWithData:[NSData dataWithContentsOfFile:cacheItem.path]];
    
    // Actually set the image and notify the completion block.
    dispatch_async(dispatch_get_main_queue(), ^{
      
      // Check that it is still valid to set the image.
      ISCacheImageView *strongSelf = weakSelf;
      if (strongSelf == nil ||
          strongSelf.callbackCount != callback) {
        return;
      }

      strongSelf.image = image;
      
      // TODO Is this really necessary?
      [self stopObservingCacheItem];
    });
    
  });
  
}


- (void)startObservingCacheItem
{
  [self.cacheItem addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(state))
                      options:NSKeyValueObservingOptionInitial
                      context:NULL];
}


- (void)stopObservingCacheItem
{
  @try {
    [self.cacheItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(state))];
  }
  @catch (NSException *exception) {}
}



- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
    if (self.cacheItem.state == ISCacheItemStateFound) {
      [self loadImageAsynchronously:self.callbackCount];
    }
  }
}


@end
