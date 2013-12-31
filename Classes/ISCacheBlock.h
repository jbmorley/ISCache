//
//  ISCacheBlock.h
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>
#import "ISCacheItemInfo.h"

typedef enum {
  // Indicates that the cache block wishes to continue receiving
  // cache updates. Updates will continue until the current item
  // fails, completes successfully or the cache block indicates
  // that it has finished in a subsequent call.
  ISCacheBlockStateContinue,
  // Indicates that the cache block has completed whatever observing
  // it set out to do and no longer wishes to receive updates.
  ISCacheBlockStateDone,
} ISCacheBlockState;

typedef ISCacheBlockState (^ISCacheBlock)(ISCacheItemInfo *info, NSError *error);
