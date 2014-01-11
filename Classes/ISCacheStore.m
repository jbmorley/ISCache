/*
 * Copyright (C) 2013-2014 InSeven Limited.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "ISCacheStore.h"
#import "ISCacheExceptions.h"

@interface ISCacheStore ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSMutableDictionary *items;

@end

@implementation ISCacheStore

static NSString *kKeyCacheStoreVersion = @"version";
static NSString *kKeyCacheStoreItems = @"items";

static NSInteger kCacheStoreVersion = 1;


+ (id)storeWithPath:(NSString *)path
{
  return [[self alloc] initWithPath:path];
}


- (id)initWithPath:(NSString *)path
{
  self = [super init];
  if (self) {
    self.path = path;
    self.items = [NSMutableDictionary dictionaryWithCapacity:3];
    
    // Load the cache items if present.
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path
                                             isDirectory:NO]) {
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
        ISCacheItem *item = [ISCacheItem itemInfoWithDictionary:dictionary];
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
}


- (void)removeItem:(ISCacheItem *)item
{
  [self.items removeObjectForKey:item.uid];
}


- (void)save
{
  // Create an array of items.
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.items.count];
  for (NSString *identifier in self.items) {
    NSDictionary *item = [self.items[identifier] dictionary];
    [items addObject:item];
  }
  
  // Create a dictionary to write to file.
  NSMutableDictionary *store =
  [NSMutableDictionary dictionaryWithObjectsAndKeys:
   @(kCacheStoreVersion),
   kKeyCacheStoreVersion,
   items,
   kKeyCacheStoreItems,
   nil];
  
  // Write the dictionary to disk.
  [store writeToFile:self.path
          atomically:YES];
}


@end
