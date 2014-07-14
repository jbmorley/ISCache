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

#import "ISCacheTask.h"
#import "ISCacheItem.h"

@interface ISCacheTask ()

@property (nonatomic, strong) ISCacheBlock completionBlock;
@property (nonatomic, strong) ISCancelToken *cancelToken;
@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, strong) ISCacheTask *retainCycle;
@property (nonatomic, strong) ISCacheItem *cacheItem;

@end

@implementation ISCacheTask


#pragma mark - ISCacheItemObserver


- (id)initWithCacheItem:(ISCacheItem *)cacheItem
        completionBlock:(ISCacheBlock)completionBlock
{
  return [self initWithCacheItem:cacheItem
                 completionBlock:completionBlock
                     cancelToken:[ISCancelToken new]];
}


- (id)initWithCacheItem:(ISCacheItem *)cacheItem
        completionBlock:(ISCacheBlock)completionBlock
            cancelToken:(ISCancelToken *)cancelToken
{
  self = [super init];
  if (self) {
    self.cacheItem = cacheItem;
    self.completionBlock = completionBlock;
    self.cancelToken = cancelToken;
    self.initialized = NO;
    [self _retain];
    [self.cancelToken addObserver:self];
    [self.cacheItem addCacheItemObserver:self
                                 options:ISCacheItemObserverOptionsInitial];
  }
  return self;
}


- (void)cancel
{
  [self.cancelToken cancel];
}


- (void)_retain
{
  self.retainCycle = self;
}


- (void)_release
{
  self.retainCycle = nil;
}


#pragma mark - ISCacheItemObserver


- (void)cacheItemDidChange:(ISCacheItem *)cacheItem
{
  if (self.cacheItem != cacheItem) {
    return;
  }
  
  if (self.cancelToken.isCancelled) {
    return;
  }
  
  if (self.cacheItem.state == ISCacheItemStateNotFound) {
    if (self.initialized) {
      self.completionBlock(self.cacheItem.lastError,
                           self.cancelToken);
      [self _release];
    } else {
      [self.cacheItem fetch];
      self.initialized = YES;
    }
  } else if (self.cacheItem.state == ISCacheItemStateInProgress) {
    // Ignore progress.
  } else if (cacheItem.state == ISCacheItemStateFound) {
    self.completionBlock(self.cacheItem.lastError,
                         self.cancelToken);
    [self _release];
  }
}


#pragma mark - ISCancelTokenObserver


- (void)tokenDidCancel
{
  [self.cacheItem removeCacheItemObserver:self];
  [self.cacheItem cancel];
}


@end
