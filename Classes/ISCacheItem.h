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

#import <Foundation/Foundation.h>
#import <ISUtilities/ISUtilities.h>
#import "ISCacheFile.h"
#import "ISCacheBlock.h"
#import "ISCacheTask.h"
#import "ISCacheItemObserver.h"

typedef enum {
  
  // The item is not present in the cache.
  ISCacheItemStateNotFound = 1,
  // The item has been requested and is waiting to start.
  ISCacheItemStateWaiting = 2,
  // The item has been requested and is in progress.
  ISCacheItemStateInProgress = 4,
  // The item is present in the cache.
  ISCacheItemStateFound = 8,
  
} ISCacheItemState;

enum {
  ISCacheItemObserverOptionsInitial = 1,
};
typedef NSUInteger ISCacheItemObserverOptions;

static const int ISCacheItemStateAll = 15;

static const int ISCacheItemTotalBytesUnknown = -1;

@class ISCache;
@class ISCacheItem;

@interface ISCacheItem : NSObject <ISCancelable>

// Read-only properties.
@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic, readonly) NSString *context;
@property (strong, nonatomic, readonly) NSDictionary *preferences;
@property (strong, nonatomic, readonly) NSString *uid;
@property (nonatomic, readonly) ISCacheItemState state;
@property (strong, nonatomic, readonly) NSDate *created;
@property (strong, nonatomic, readonly) NSDate *modified;
@property (strong, nonatomic, readonly) NSError *lastError;

// Read-write properties.
// TODO These should not be read-write for the normal clients.
@property (nonatomic) long long totalBytesRead;
@property (nonatomic) long long totalBytesExpectedToRead;
@property (strong, nonatomic) NSDictionary *userInfo;

// Calculated properties.
@property (readonly) float progress;
@property (readonly) NSTimeInterval timeRemainingEstimate;

- (NSArray *)files;
- (ISCacheFile *)file:(NSString *)name;
- (ISCacheFile *)file;

- (void)fetch;
- (void)remove;
- (void)cancel;

- (void)addCacheItemObserver:(id<ISCacheItemObserver>)observer
                     options:(ISCacheItemObserverOptions)options;
- (void)removeCacheItemObserver:(id<ISCacheItemObserver>)observer;

- (ISCacheTask *)then:(ISCacheBlock)completionBlock;
- (ISCacheTask *)then:(ISCacheBlock)completionBlock
          cancelToken:(ISCancelToken *)cancelToken;

@end
