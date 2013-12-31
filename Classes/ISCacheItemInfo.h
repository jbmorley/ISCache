//
//  ISCacheItemInfo.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>

typedef enum {
  
  // The item is not present in the cache.
  ISCacheItemStateNotFound = 0,

  // The item has been requested but the fetch has either
  // not begun, or no progress information is known.
  ISCacheItemStatePending = 1,

  // The item has been requested and its progress is known.
  ISCacheItemStateInProgress = 2,
  
  // The item is present in the cache.
  ISCacheItemStateFound = 4,
  
} ISCacheItemState;

@interface ISCacheItemInfo : NSObject

@property (strong) NSString *item;
@property (strong) NSString *context;
@property (strong) NSDictionary *userInfo;
@property (strong) NSString *identifier;
@property (strong) NSString *path;
@property ISCacheItemState state;
@property long long totalBytesRead;
@property long long totalBytesExpectedToRead;

+ (id)itemInfoWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;
- (void)openFile;
- (void)closeFile;
- (void)writeDataToFile:(NSData *)data;

@end
