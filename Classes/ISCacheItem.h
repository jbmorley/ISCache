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

#import <Foundation/Foundation.h>

typedef enum {
  
  // The item is not present in the cache.
  ISCacheItemStateNotFound = 0,

  // The item has been requested and is in progress.
  ISCacheItemStateInProgress = 1,
  
  // The item is present in the cache.
  ISCacheItemStateFound = 2,
  
} ISCacheItemState;

static const int ISCacheItemStateAll = 7;

static const int ISCacheItemTotalBytesUnknown = -1;

@interface ISCacheItem : NSObject

@property (strong, readonly) NSString *item;
@property (strong, readonly) NSString *context;
@property (strong, readonly) NSDictionary *userInfo;
@property (strong, readonly) NSString *uid;
@property (strong, readonly) NSString *path;

@property ISCacheItemState state;
@property long long totalBytesRead;
@property long long totalBytesExpectedToRead;
@property (strong) NSDate *created;
@property (strong) NSDate *modified;
@property (strong) NSError *lastError;

@property (readonly) CGFloat progress;

+ (id)itemWithItem:(NSString *)item
           context:(NSString *)context
          userInfo:(NSDictionary *)userInfo
               uid:(NSString *)identifier
              path:(NSString *)path;
- (id)initWithItem:(NSString *)item
           context:(NSString *)context
          userInfo:(NSDictionary *)userInfo
               uid:(NSString *)uid
              path:(NSString *)path;

+ (id)itemInfoWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;

- (void)openFile;
- (void)closeFile;
- (void)deleteFile;
- (void)writeDataToFile:(NSData *)data;

@end
