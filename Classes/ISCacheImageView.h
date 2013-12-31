//
//  ISCacheImageView.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 30/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISCacheCompletionBlock.h"
#import "ISCacheObserver.h"

@interface ISCacheImageView : UIImageView
<ISCacheObserver>

- (void)setImageWithURL:(NSString *)url
               userInfo:(NSDictionary *)userInfo;
- (void)setImageWithURL:(NSString *)url
               userInfo:(NSDictionary *)userInfo
        completionBlock:(ISCacheCompletionBlock)completionBlock;

@end
