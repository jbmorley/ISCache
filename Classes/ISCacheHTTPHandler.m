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
#import <ISUtilities/UIApplication+Activity.h>

@interface ISCacheHTTPHandler ()

@property (nonatomic, weak) id<ISCacheHandlerDelegate> delegate;
@property (nonatomic, strong) ISCacheItem *info;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, copy) ISCachePostProcessBlock completionBlock;
@property (nonatomic) BOOL supportsResume;
@property (nonatomic) NSInteger requestCount;
@property (nonatomic) int statusCode;

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
  [[UIApplication sharedApplication] beginNetworkActivity];
  self.requestCount++;
  NSMutableURLRequest *request =
  [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.info.identifier]];
  
  if (self.info.totalBytesExpectedToRead > 0 &&
      self.supportsResume) {
    [request setValue:[NSString stringWithFormat:
                       @"bytes=%llu-",
                       self.info.totalBytesRead]
   forHTTPHeaderField:@"Range"];
  }
  
  self.connection =
  [NSURLConnection connectionWithRequest:request
                                delegate:self];
  [self.connection start];
}


- (void)cancel
{
  [self.connection cancel];
  [[UIApplication sharedApplication] endNetworkActivity];
}


#pragma mark - NSURLConnectionDelegate


- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
  
  // Check for error responses.
  // TODO What other errors do I need to check for.
  self.statusCode = [((NSHTTPURLResponse *)response) statusCode];
  if (self.statusCode == 404)
  {
    [connection cancel];
    [self.delegate item:self.info
       didFailWithError:[NSError errorWithDomain:@"s" code:0 userInfo:nil]];
    [self.delegate log:@"didReceiveResponse statusCode with %i", self.statusCode];
    return;
  }
  
  // If the request count is greater than 1 we are attempting a resume
  // meaning that the content length is not guaranteed to be the full size.
  if (self.requestCount == 1) {
    self.info.totalBytesExpectedToRead = response.expectedContentLength;
  }
  
  self.filename = response.suggestedFilename;
  
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
  if ([response respondsToSelector:@selector(allHeaderFields)]) {
    NSDictionary *dictionary = [httpResponse allHeaderFields];
    [self.delegate log:@"Headers: %@", dictionary];
    if ([dictionary[@"Accept-Ranges"] isEqualToString:@"bytes"]) {
      self.supportsResume = YES;
    }
  }
}


- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
  [self.delegate log:@"connection:didReceiveData:"];
  self.info.totalBytesRead += [data length];
  [[self.info file:self.filename] appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  [[UIApplication sharedApplication] endNetworkActivity];
  if(self.info.totalBytesRead !=
     self.info.totalBytesExpectedToRead) {
    [self restartOrFailWithError:[NSError errorWithDomain:@"s" code:0 userInfo:nil]];
    return;
  }
  
  [[self.info file:self.filename] close];
  
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
  [[UIApplication sharedApplication] endNetworkActivity];
  [self.delegate log:@"connection:didFailWithError:"];
  [self restartOrFailWithError:error];
}

- (void)restartOrFailWithError:(NSError *)error
{
  [self.delegate log:@"Restarting download..."];
  if (self.supportsResume) {
    [self start];
  } else {
    [self.delegate item:self.info
       didFailWithError:error];
  }
}

- (BOOL)supportsBackgroundFetch
{
  return YES;
}

@end
