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

#import "ISCacheScalingHandlerFactory.h"
#import "ISCacheHTTPHandler.h"
#import <ISUtilities/UIImage+Utilities.h>

const NSString *ISCacheImageWidth = @"width";
const NSString *ISCacheImageHeight = @"height";
const NSString *ISCacheImageScaleMode = @"scale";

@implementation ISCacheScalingHandlerFactory

- (void)createHandlerForContext:(NSString *)context
                       userInfo:(NSDictionary *)userInfo
                completionBlock:(ISCacheHandlerFactoryCompletionBlock)completionBlock
{
  ISCacheHTTPHandler *handler = [[ISCacheHTTPHandler alloc] initWithCompletion:^(ISCacheItem *info) {
    
    // Only attempt to resize the image if user info has been
    // provided with the required dimensions.
    if (userInfo) {
      
      CGSize targetSize = CGSizeMake([userInfo[ISCacheImageWidth] floatValue],
                                     [userInfo[ISCacheImageHeight] floatValue]);
      ISImageScale scale = (ISImageScale)[userInfo[ISCacheImageScaleMode] integerValue];
      
      UIImage *image = [UIImage imageWithData:info.file.data];
      
      UIImage *scaledImage = [image imageWithSize:targetSize
                                      scalingMode:scale];
            
      // Save the image.
      [UIImagePNGRepresentation(scaledImage) writeToFile:info.file.path
                                           atomically:YES];
    }
    
    return (NSError *)nil;
    
  }];
  completionBlock(handler);
}

@end
