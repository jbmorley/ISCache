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

#import "ISCacheHTTPHandler.h"
#import "ISCache.h"

@interface ISCacheHTTPHandler ()

@property (nonatomic, weak) id<ISCacheHandlerDelegate> delegate;
@property (nonatomic, strong) ISCacheItem *info;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, copy) ISCachePostProcessBlock completionBlock;
@property (nonatomic) BOOL supportsResume;
@property (nonatomic) NSInteger requestCount;
@property (nonatomic) long long totalBytesExpectedToRead;
@property (nonatomic) long long totalBytesRead;

@end

@implementation ISCacheHTTPHandler

- (id)init
{
  return [self initWithCompletion:NULL];
}

- (id)initWithCompletion:(ISCachePostProcessBlock)completionBlock
{
  self = [super init];
  if (self) {
    self.completionBlock = completionBlock;
    self.requestCount = 0;
  }
  return self;
}


- (void)fetchItem:(ISCacheItem *)info
         delegate:(id<ISCacheHandlerDelegate>)delegate
{
  self.delegate = delegate;
  self.info = info;
  [self start];
}


- (void)start
{
  self.requestCount++;
  NSMutableURLRequest *request =
  [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.info.identifier]];
  
  if (self.totalBytesExpectedToRead > 0 &&
      self.supportsResume) {
    [request setValue:[NSString stringWithFormat:
                       @"bytes=%llu-",
                       self.totalBytesRead]
   forHTTPHeaderField:@"Range"];
  }
  
  self.connection = [NSURLConnection connectionWithRequest:request
                                                  delegate:self];
  
  [self.connection start];
}


- (void)cancel
{
  [self.connection cancel];
}


#pragma mark - NSURLConnectionDelegate


- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
  // If the request count is greater than 1 we are attempting a resume
  // meaning that the content length is not guaranteed to be the full size.
  if (self.requestCount == 1) {
    self.info.totalBytesExpectedToRead = response.expectedContentLength;
    self.totalBytesExpectedToRead = response.expectedContentLength;
  }
  
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
  if ([response respondsToSelector:@selector(allHeaderFields)]) {
    NSDictionary *dictionary = [httpResponse allHeaderFields];
    [self.delegate log:@"Headers: %@", dictionary];
    if ([dictionary[@"Accept-Ranges"] isEqualToString:@"bytes"]) {
      self.supportsResume = YES;
    }
  }
  
  [self.delegate itemDidUpdate:self.info];
  [self.delegate log:
   @"totalBytesExpectedToRead: %llu",
   self.totalBytesExpectedToRead];
}


- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
  [self.delegate log:@"connection:didReceiveData:"];
  
  self.info.totalBytesRead += [data length];
  self.totalBytesRead += [data length];
  [self.info writeDataToFile:data];
  [self.delegate itemDidUpdate:self.info];
}


- (void)connectionDidResumeDownloading:(NSURLConnection *)connection
                     totalBytesWritten:(long long)totalBytesWritten
                    expectedTotalBytes:(long long)expectedTotalBytes
{
  [self.delegate log:@"connectionDidResumeDownloading:"];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  [self.info closeFile];
  
  // Schedule the post-processing if neccessary.
  // Otherwise, simply call the final block.
  if (self.completionBlock) {
    
    dispatch_queue_t queue =
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
      NSError *error = self.completionBlock(self.info);
      
      // Signal that the resizing is complete.
      dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
          [self.delegate item:self.info
             didFailWithError:error];
        } else {
          [self.delegate itemDidFinish:self.info];
        }
      });
      
    });
  } else {
    [self.delegate itemDidFinish:self.info];
  }
}


- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  [self.delegate log:@"connection:didFailWithError:"];
  if (self.supportsResume) {
    
    // TODO Is this the right check?
    if (self.totalBytesRead ==
        self.totalBytesExpectedToRead) {
      [self.delegate itemDidFinish:self.info];
    } else {

      // TODO Only resume when it makes sense.
      [self.delegate log:
       @"resuming: read %llu, expected %llu",
       self.totalBytesRead,
       self.totalBytesExpectedToRead];
      [self start];
    }
    
  } else {
    [self.delegate item:self.info
       didFailWithError:error];
  }
}


@end
