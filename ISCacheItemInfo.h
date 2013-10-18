//
//  ISCacheItemInfo.h
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import <Foundation/Foundation.h>

typedef enum {
  
  ISCacheItemStateNotFound,
  ISCacheItemStateInProgress,
  ISCacheItemStateFound,
  
} ISCacheItemState;

@interface ISCacheItemInfo : NSObject

@property (strong) NSString *item;
@property (strong) NSString *context;
@property (strong) NSString *path;
@property ISCacheItemState state;
@property long long totalBytesRead;
@property long long totalBytesExpectedToRead;

- (void)openFile;
- (void)closeFile;
- (void)writeDataToFile:(NSData *)data;

@end
