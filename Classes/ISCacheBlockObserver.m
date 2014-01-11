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
