/*
 * Copyright (C) 2013-2014 InSeven Limited.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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
    
    return (NSError *)nil;
    
  }];
  return handler;
}

@end
