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

#import "ISCacheStore.h"
#import "ISCacheExceptions.h"
#import "ISCache.h"

@interface ISCacheStore ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSMutableDictionary *items;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic) BOOL dirty;

@end

@implementation ISCacheStore

static NSString *kKeyCacheStoreVersion = @"version";
static NSString *kKeyCacheStoreItems = @"items";

static NSInteger kCacheStoreVersion = 1;


+ (id)storeWithPath:(NSString *)path
              cache:(ISCache *)cache
{
  return [[self alloc] initWithPath:path
                              cache:cache];
}


- (id)initWithPath:(NSString *)path
             cache:(ISCache *)cache
{
  self = [super init];
  if (self) {
    self.path = path;
    self.cache = cache;
    self.items = [NSMutableDictionary dictionaryWithCapacity:3];
    
    // Load the cache items if present.
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path
                                             isDirectory:&isDirectory]) {
      NSDictionary *store = [NSDictionary dictionaryWithContentsOfFile:self.path];
      
      // Check the version.
      NSNumber *version = store[kKeyCacheStoreVersion];
      if (!version ||
          [version integerValue] != kCacheStoreVersion) {
        @throw [NSException exceptionWithName:ISCacheExceptionUnsupportedCacheStoreVersion
                                       reason:ISCacheExceptionUnsupportedCacheStoreVersionReason
                                     userInfo:nil];
      }
      
      // Load the items.
      for (NSDictionary *dictionary in store[kKeyCacheStoreItems]) {
        ISCacheItem *item = [ISCacheItem itemInfoWithDictionary:dictionary
                             cache:self.cache];
        [self.items setObject:item
                       forKey:item.uid];
      }
    }
  }
  return self;
}


- (ISCacheItem *)item:(NSString *)identifier
{
  return [self.items objectForKey:identifier];
}


- (NSArray *)items:(id <ISCacheFilter>)filter
{
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:3];
  for (NSString *identifier in self.items) {
    ISCacheItem *item = self.items[identifier];
    if ([filter matchesFilter:item]) {
      [items addObject:item];
    }
  }
  return items;
}


- (void)addItem:(ISCacheItem *)item
{
  [self.items setObject:item
                 forKey:item.uid];
  [self save];
}


- (void)removeItem:(ISCacheItem *)item
{
  [self.items removeObjectForKey:item.uid];
}


- (void)save
{
  @synchronized (self) {
    self.dirty = YES;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    
    NSArray *items = nil;
    @synchronized (self) {
      if (self.dirty) {
        items = [[self.items allValues] copy];
        self.dirty = NO;
      } else {
        return;
      }
    }
    
    // Create the dictionaries.
    NSMutableArray *dictionaries =
    [NSMutableArray arrayWithCapacity:items.count];
    for (ISCacheItem *item in items) {
      [dictionaries addObject:[item dictionary]];
    }
    
    // Create a dictionary to write to file.
    NSMutableDictionary *store =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     @(kCacheStoreVersion),
     kKeyCacheStoreVersion,
     dictionaries,
     kKeyCacheStoreItems,
     nil];
    
    // Write the dictionary to disk.
    BOOL success = [store writeToFile:self.path
                           atomically:YES];
    if (!success) {
      @throw [NSException exceptionWithName:ISCacheExceptionUnableToSaveStore
                                     reason:ISCacheExceptionUnableToSaveStoreReason
                                   userInfo:nil];

    }

  });
}


@end
