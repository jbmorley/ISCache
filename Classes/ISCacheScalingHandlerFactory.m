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

#import "ISCacheScalingHandlerFactory.h"
#import "ISCacheHTTPHandler.h"

@implementation ISCacheScalingHandlerFactory

- (id<ISCacheHandler>)createHandler:(NSDictionary *)userInfo
{
  ISCacheHTTPHandler *handler = [[ISCacheHTTPHandler alloc] initWithCompletion:^(ISCacheItem *info) {
    
    // Only attempt to resize the image if user info has been
    // provided with the required dimensions.
    if (userInfo) {
      
      UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
      
      // Get the current image dimensions.
      CGSize currentSize = image.size;
      
      // Get the target dimensions.
      CGSize targetSize = CGSizeMake([userInfo[@"width"] floatValue],
                                     [userInfo[@"height"] floatValue]);
      
      ISScalingCacheHandlerScale scale = (ISScalingCacheHandlerScale)[userInfo[@"scale"] integerValue];
      
      // Calculate the appropriate dimensions.
      CGSize newSize = targetSize;
      CGSize canvasSize = targetSize;
      if (scale == ISScalingCacheHandlerScaleAspectFit) {
        
        CGFloat targetRatio = targetSize.width/targetSize.height;
        CGFloat currentRatio = currentSize.width/currentSize.height;
        
        if (currentRatio < targetRatio) {
          newSize.height = targetSize.width / currentRatio;
        } else {
          newSize.width = targetSize.height * currentRatio;
        }
        
        // Since we're using a 'fit' the canvas size and new size
        // will always be equal.
        canvasSize = newSize;
        
      } else if (scale == ISScalingCacheHandlerScaleAspectFill) {
        
        CGFloat targetRatio = targetSize.width/targetSize.height;
        CGFloat currentRatio = currentSize.width/currentSize.height;
        
        if (currentRatio < targetRatio) {
          newSize.height = targetSize.height / currentRatio;
        } else {
          newSize.width = targetSize.width * currentRatio;
        }
        
        // Since we're using a 'fill' the canvas size will always
        // be the requested size.
        canvasSize = targetSize;
        
      }
      
      // Resize the image.
      CGFloat screenScale = [[UIScreen mainScreen] scale];
      UIGraphicsBeginImageContextWithOptions(canvasSize,
                                             NO,
                                             screenScale);
      [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
      UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      
      // Save the image.
      [UIImagePNGRepresentation(newImage) writeToFile:info.path
                                           atomically:YES];
      
    }
    
    return (NSError *)nil;
    
  }];
  return handler;
}

@end
