//
// Copyright (c) 2013-2014 InSeven Limited.
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
#import <ISUtilities/ISNotifier.h>

@interface ISCacheItem ()

@property (weak) ISCache *cache;
@property (nonatomic, strong) NSMutableDictionary *fileDict;
@property (nonatomic, strong) NSString *root;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) ISNotifier *notifier;
@property (nonatomic, strong) ISNotifier *progressNotifier;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) uint64_t fmdbId;

// Used for tracking progress update granularity.
@property (nonatomic, assign) CGFloat lastProgress;
@property (nonatomic, strong) NSDate *lastProgressDate;

- (id)_initWithResultSet:(FMResultSet *)resultSet
                    root:(NSString *)root
                   cache:(ISCache *)cache;
- (id)_initWithIdentifier:(NSString *)identifier
                  context:(NSString *)context
              preferences:(NSDictionary *)preferences
                      uid:(NSString *)uid
                     root:(NSString *)root
                     path:(NSString *)path
                    cache:(ISCache *)cache;
- (void)_transitionToInProgress;
- (void)_transitionToFound;
- (void)_transitionToNotFound;
- (void)_transitionToError:(NSError *)error;

- (void)_updateModified;

- (BOOL)_filesExist;

@end
