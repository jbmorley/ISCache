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

#import "ISCacheStore.h"
#import "ISCacheExceptions.h"
#import "ISCache.h"
#import "ISCacheItemPrivate.h"

@interface ISCacheStore ()

@property (nonatomic, strong) NSMutableDictionary *items;

@end

@implementation ISCacheStore

- (id)init
{
  self = [super init];
  if (self) {
    self.items = [NSMutableDictionary new];
  }
  return self;
}

- (ISCacheItem *)item:(NSString *)identifier
{
  return [self.items objectForKey:identifier];
}

- (NSArray *)items:(id <ISCacheFilter>)filter
{
  if (filter) {
    NSMutableArray *items = [NSMutableArray new];
    for (NSString *identifier in self.items) {
      ISCacheItem *item = self.items[identifier];
      if ([filter matchesFilter:item]) {
        [items addObject:item];
      }
    }
    return items;
  } else {
    return [self.items copy];
  }
}

- (void)addItem:(ISCacheItem *)item
{
  [self.items setObject:item
                 forKey:item.uid];
}

- (void)removeItem:(ISCacheItem *)item
{
  [self.items removeObjectForKey:item.uid];
}


- (void)removeItems:(NSArray *)items
{
  for (ISCacheItem *item in items) {
    [self removeItem:item];
  }
}

@end
