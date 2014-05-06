//
// Copyright (c) 2013-2014 InSeven Limited.
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
#import "ISCachePrivate.h"
#import <objc/runtime.h>

@interface ISCacheImageView ()

@property (nonatomic, strong) ISCacheItem *cacheItem;
@property (nonatomic, copy) ISCacheCompletionBlock block;
@property (nonatomic) BOOL observing;
@property (nonatomic, strong) ISCancelToken *cancelToken;

@end

@implementation ISCacheImageView


- (void)dealloc
{
  [self.cancelToken cancel];
}


- (ISCacheItem *)setImageWithIdentifier:(NSString *)identifier
                                context:(NSString *)context
                            preferences:(NSDictionary *)preferences
                       placeholderImage:(UIImage *)placeholderImage
                                  block:(ISCacheCompletionBlock)block
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
  
  // Cancel the previous fetch.
  [self.cancelToken cancel];
  
  // We always set the placeholder image as image loading is
  // performed asynchronously so may take some time to complete.
  if (placeholderImage) {
    self.image = placeholderImage;
  } else {
    self.image = nil;
  }
  
  // Store the cache item and observe it.
  self.block = block;
  self.cacheItem = item;
  self.cancelToken = [ISCancelToken new];
  [self.cacheItem
   then:^(NSError *error, ISCancelToken *cancelToken) {
     
     // Give up on errors.
     if (error) {
       return;
     }
    
    ISCacheImageView *__weak weakSelf = self;
    ISCacheItem *cacheItem = self.cacheItem;
    [UIImage loadImage:cacheItem.file.path
            completion:
     ^(NSUInteger identifier, UIImage *image) {
       ISCacheImageView *strongSelf = weakSelf;
       
       // Guard against expired requests.
       if (strongSelf == nil ||
           cancelToken.isCancelled) {
         return;
       }
       
       // Set the image.
       strongSelf.image = image;
       
       // Notify the client of the success.
       if (self.block) {
         self.block(nil);
       }
       
     }];
    
  }
   cancelToken:self.cancelToken];
  
  
  // We do not explicitly fetch the item here; this is done
  // as a result of the initial property value observeration.
  
  return item;
}


- (void)cancelSetImage
{
  [self.cancelToken cancel];
}


@end
