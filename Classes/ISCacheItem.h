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

#import <Foundation/Foundation.h>
#import <ISUtilities/ISUtilities.h>
#import <FMDB/FMDB.h>
#import "ISCacheFile.h"
#import "ISCacheBlock.h"
#import "ISCacheTask.h"
#import "ISCacheItemObserver.h"

typedef NS_ENUM(NSUInteger, ISCacheItemState) {

  /**
   * The item is not present in the cache.
   */
  ISCacheItemStateNotFound = 1,
  
  /**
   * The item has been requested and is in progress.
   */
  ISCacheItemStateInProgress = 4,
  
  /**
   * The item is present in the cache.
   */
  ISCacheItemStateFound = 8,
  
};

typedef NS_OPTIONS(NSUInteger, ISCacheItemObserverOptions) {
  
  ISCacheItemObserverOptionsInitial = 1,
  
};

static const int ISCacheItemStateAll = 15;

static const int ISCacheItemTotalBytesUnknown = -1;

@class ISCache;
@class ISCacheItem;


@interface ISCacheItemInfo : NSObject

@property (nonatomic, readonly, assign) ISCacheItemState state;
@property (nonatomic, readonly, assign) float progress;
@property (nonatomic, readonly, assign) NSTimeInterval timeRemainingEstimate;

// TODO Are these actually generic or is it better if these are calculated
// by the downloader? How do we decide whether we should be notifying the
// client of progress updates? Is it better if progress is computed?
@property (nonatomic, readonly, assign) long long totalBytesRead;
@property (nonatomic, readonly, assign) long long totalBytesExpectedToRead;

@end


@interface ISCacheItem : NSObject <ISCancelable>

// Read-only properties.
@property (strong, readonly) NSString *identifier;
@property (strong, readonly) NSString *context;
@property (strong, readonly) NSString *uid;
@property (readonly, assign) ISCacheItemState state;
@property (strong, readonly) NSDate *created;
@property (strong, readonly) NSDate *modified;
@property (strong, readonly) NSError *lastError;

// Read-write properties.
// TODO These should not be read-write for the normal clients.
@property (nonatomic) long long totalBytesRead;
@property (nonatomic) long long totalBytesExpectedToRead;

@property (nonatomic, strong) FMDatabase *fmdb;

// Calculated properties.
@property (readonly) float progress;
@property (readonly) NSTimeInterval timeRemainingEstimate;

- (NSArray *)files;
- (ISCacheFile *)file:(NSString *)name;
- (ISCacheFile *)file;

- (void)fetch;
- (void)remove;
- (void)cancel;
- (void)save;

- (void)addCacheItemObserver:(id<ISCacheItemObserver>)observer
                     options:(ISCacheItemObserverOptions)options;
- (void)removeCacheItemObserver:(id<ISCacheItemObserver>)observer;
- (void)addCacheItemProgressObserver:(id<ISCacheItemProgressObserver>)observer;
- (void)removeCacheItemProgressObserver:(id<ISCacheItemProgressObserver>)observer;

- (ISCacheTask *)then:(ISCacheBlock)completionBlock;
- (ISCacheTask *)then:(ISCacheBlock)completionBlock
          cancelToken:(ISCancelToken *)cancelToken;

@end
