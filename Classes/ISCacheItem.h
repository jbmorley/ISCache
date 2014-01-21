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

@property (strong, readonly) NSString *identifier;
@property (strong, readonly) NSString *context;
@property (strong, readonly) NSDictionary *userInfo;
@property (strong, readonly) NSString *uid;
@property (strong, readonly) NSString *path;
@property (strong) NSDictionary *data;

@property ISCacheItemState state;
@property long long totalBytesRead;
@property long long totalBytesExpectedToRead;
@property (strong) NSDate *created;
@property (strong) NSDate *modified;
@property (strong) NSError *lastError;

@property (readonly) CGFloat progress;

+ (id)itemWithIdentifier:(NSString *)identifier
           context:(NSString *)context
          userInfo:(NSDictionary *)userInfo
               uid:(NSString *)uid
              path:(NSString *)path;
- (id)initWithIdentifier:(NSString *)identifier
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
