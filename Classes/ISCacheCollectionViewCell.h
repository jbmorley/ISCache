//
//  ISDownloadsCollectionViewCell.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 16/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ISCache/ISCache.h>

@interface ISCacheCollectionViewCell : UICollectionViewCell
<ISCacheItemObserver>

@property (nonatomic, strong) ISCacheItem *cacheItem;

@end