//
//  ISScalingCacheHandlerFactory.m
//  
//
//  Created by Jason Barrie Morley on 29/12/2013.
//
//

#import "ISScalingCacheHandlerFactory.h"
#import "ISHTTPCacheHandler.h"

@implementation ISScalingCacheHandlerFactory

- (id<ISCacheHandler>)createHandler:(NSDictionary *)userInfo
{
  ISHTTPCacheHandler *handler = [[ISHTTPCacheHandler alloc] initWithCompletion:^(ISCacheItemInfo *info, ISCacheItemReady completeBlock) {
    
    // Only attempt to resize the image if user info has been
    // provided with the required dimensions.
    if (userInfo) {
      
      UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
      
      // Get the current image dimensions.
      CGSize currentSize = image.size;
      
      // Get the target dimensions.
      CGSize targetSize = CGSizeMake([userInfo[@"width"] floatValue],
                                     [userInfo[@"height"] floatValue]);
      
      ISScalingCacheHandlerScale scale = [userInfo[@"scale"] integerValue];
      
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
    
    // Signal that the resizing is complete.
    completeBlock();
    
  }];
  return handler;
}

@end
