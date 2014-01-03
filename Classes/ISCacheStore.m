//
//  ISCacheStore.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 03/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISCacheStore.h"

@interface ISCacheStore ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSMutableDictionary *items;

@end

@implementation ISCacheStore


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
      NSDictionary *items = [NSDictionary dictionaryWithContentsOfFile:self.path];
      for (NSString *identifier in items) {
        ISCacheItem *item = [ISCacheItem itemInfoWithDictionary:items[identifier]];
        [self.items setObject:item
                      forKey:identifier];
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
  // Create a dictionary into which we will place the items.
  NSMutableDictionary *items = [NSMutableDictionary dictionaryWithCapacity:self.items.count];
  
  // Add item dictionaries into the dictionary.
  for (NSString *identifier in self.items) {
    NSDictionary *item = [self.items[identifier] dictionary];
    [items setObject:item
              forKey:identifier];
  }
  
  // Write the dictionary to disk.
  [items writeToFile:self.path
          atomically:YES];
}


@end
