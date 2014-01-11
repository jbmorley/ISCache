//
//  ISHTTPCacheHandler.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 11/08/2013.
//
//

#import "ISCacheHTTPHandler.h"
#import "ISCache.h"

@interface ISCacheHTTPHandler ()

@property (nonatomic, weak) id<ISCacheHandlerDelegate> delegate;
@property (nonatomic, strong) ISCacheItem *info;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, copy) ISCachePostProcessBlock completionBlock;

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
  }
  return self;
}


- (void)fetchItem:(ISCacheItem *)info
         delegate:(id<ISCacheHandlerDelegate>)delegate
{
  self.delegate = delegate;
  self.info = info;
  
  self.connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:info.item]] delegate:self];
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
  self.info.totalBytesExpectedToRead = response.expectedContentLength;
  [self.delegate itemDidUpdate:self.info];
}


- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
  self.info.totalBytesRead += [data length];
  [self.info writeDataToFile:data];
  [self.delegate itemDidUpdate:self.info];
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
  [self.delegate item:self.info
     didFailWithError:error];
}


@end