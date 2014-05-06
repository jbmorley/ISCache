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

#import "ISCacheAFNetworkingHandler.h"
#import "AFNetworking.h"

@interface ISCacheAFNetworkingHandler ()

@property (nonatomic, strong) ISCacheItem *cacheItem;
@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, weak) id<ISCacheHandlerUpdater> updater;

@end

@implementation ISCacheAFNetworkingHandler


- (void)fetchItem:(ISCacheItem *)cacheItem
          updater:(id<ISCacheHandlerUpdater>)updater
{
  self.cacheItem = cacheItem;
  self.updater = updater;
  
  NSURLSessionConfiguration *configuration =
  [NSURLSessionConfiguration defaultSessionConfiguration];
  self.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
  NSURL *URL = [NSURL URLWithString:cacheItem.identifier];
  NSURLRequest *request =
  [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
  
  self.downloadTask = [self.manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
    return [NSURL fileURLWithPath:[self.cacheItem file:[response suggestedFilename]].path];
  } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
    if (error) {
      [updater item:cacheItem didFailWithError:error];
      [self.downloadTask resume];
    } else {
      [updater itemDidFinish:cacheItem];
    }
  }];
  
  __weak ISCacheAFNetworkingHandler *weakSelf = self;
  [self.manager setDownloadTaskDidWriteDataBlock:
   ^(NSURLSession *session,
     NSURLSessionDownloadTask *downloadTask,
     int64_t bytesWritten,
     int64_t totalBytesWritten,
     int64_t totalBytesExpectedToWrite) {
     ISCacheAFNetworkingHandler *strongSelf = weakSelf;
     if (strongSelf) {
       strongSelf.cacheItem.totalBytesExpectedToRead = totalBytesExpectedToWrite;
       strongSelf.cacheItem.totalBytesRead = totalBytesWritten;
     }
  }];
  
  [self.downloadTask resume];
}


- (void)cancel
{
  [self.downloadTask cancel];
  [self.updater itemDidCancel:self.cacheItem];
}


- (void)finalize
{
  NSLog(@"Cleanup!");
}


- (BOOL)supportsBackgroundFetch
{
  return YES;
}


@end
