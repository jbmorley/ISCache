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

#import "ISCacheBlockObserver.h"
#import "ISCache.h"

@interface ISCacheBlockObserver ()

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, copy) ISCacheBlock block;

@end

@implementation ISCacheBlockObserver

+ (id)observerWithItem:(ISCacheItem *)item
                 block:(ISCacheBlock)block
{
  return [[self alloc] initWithItem:item
                              block:block];
}


- (id)initWithItem:(ISCacheItem *)item
             block:(ISCacheBlock)block
{
  self = [super init];
  if (self) {
    self.identifier = item.uid;
    self.block = block;
  }
  return self;
}


- (void)cache:(ISCache *)cache
itemDidUpdate:(ISCacheItem *)item
{
  // Ignore updates that aren't meant for us.
  if ([item.uid isEqualToString:self.identifier]) {
    
    // Call our block.
    ISCacheBlockState result = self.block(item);
    
    // Remove ourselves if the item is complete, if the
    // block observer indicates that it is complete, or if
    // we have encountered an error.
    // While strictly lastError should only ever be set if the
    // state is ISCacheItemStateNotFound, it is safer to always
    // check for a non-nil lastError.
    if (item.state == ISCacheItemStateFound ||
        result == ISCacheBlockStateDone ||
        item.lastError) {
      [cache removeObserver:self];
    }
  }
}


@end
