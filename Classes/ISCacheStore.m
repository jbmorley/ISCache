//
//  ISCacheStore.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 03/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

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
          [version integerValue] == kCacheStoreVersion) {
        @throw [NSException exceptionWithName:ISCacheExceptionUnsupportedCacheStoreVersion
                                       reason:ISCacheExceptionUnsupportedCacheStoreVersionReason
                                     userInfo:nil];
      }
      
      // Load the items.
      for (NSDictionary *dictionary in store[kKeyCacheStoreItems]) {
        ISCacheItem *item = [ISCacheItem itemInfoWithDictionary:dictionary];
        [self.items setObject:item
                      forKey:item.identifier];
      }
    }
  }
  return self;
}


- (ISCacheItem *)item:(NSString *)identifier
{
  return [self.items objectForKey:identifier];
}


- (NSArray *)items:(int)states
{
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:3];
  for (NSString *identifier in self.items) {
    ISCacheItem *item = self.items[identifier];
    if ((item.state & states) > 0) {
      [items addObject:item];
    }
  }
  return items;
}


- (void)addItem:(ISCacheItem *)item
{
  [self.items setObject:item
                 forKey:item.identifier];
}


- (void)removeItem:(ISCacheItem *)item
{
  [self.items removeObjectForKey:item.identifier];
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
