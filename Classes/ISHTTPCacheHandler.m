//
//  ISHTTPCacheHandler.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 11/08/2013.
//
//

#import "ISHTTPCacheHandler.h"
#import "ISCache.h"

@interface ISHTTPCacheHandler ()

@property (nonatomic, weak) id<ISCacheHandlerDelegate> delegate;
@property (nonatomic, strong) ISCacheItemInfo *info;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, copy) ISCacheBlock completionBlock;

@end

@implementation ISHTTPCacheHandler

- (id)init
{
  return [self initWithCompletion:NULL];
}

- (id)initWithCompletion:(ISCacheBlock)completionBlock
{
  self = [super init];
  if (self) {
    self.completionBlock = completionBlock;
  }
  return self;
}


- (void)fetchItem:(ISCacheItemInfo *)info
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
  self.info = ISCacheItemStateNotFound;
  [self.delegate itemDidUpdate:self.info];
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
  if (self.completionBlock) {
    self.completionBlock(self.info);
  }
  [self.delegate itemDidFinish:self.info];
}


- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  NSAssert(YES, @"connection:didFailWithError:");
}


@end
