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

  // The item has been requested and is in progress.
  ISCacheItemStateInProgress = 1,
  
  // The item is present in the cache.
  ISCacheItemStateFound = 2,
  
} ISCacheItemState;

static const int ISCacheItemStateAll = 7;

static const int ISCacheItemTotalBytesUnknown = -1;

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
- (void)deleteFile;
- (void)writeDataToFile:(NSData *)data;

@end
