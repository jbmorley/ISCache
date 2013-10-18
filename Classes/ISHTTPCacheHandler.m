//
//  ISHTTPCacheHandler.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 11/08/2013.
//
//

#import "ISHTTPCacheHandler.h"
#import <AFNetworking/AFNetworking.h>

@interface ISHTTPCacheHandler ()

@property (weak, nonatomic) id<ISCacheHandlerDelegate> delegate;
@property (strong, nonatomic) ISCacheItemInfo *info;
@property (strong, nonatomic) NSURLConnection *connection;

@end

@implementation ISHTTPCacheHandler

- (id)init
{
  self = [super init];
  if (self) {
    
  }
  return self;
}

- (void)fetchItem:(ISCacheItemInfo *)info
         delegate:(id<ISCacheHandlerDelegate>)delegate
{
  NSLog(@"ISHTTPCacheHandler fetchItem: %@", info);
  self.delegate = delegate;
  self.info = info;
  
  // TODO Add a handler for when done.
  
  self.connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:info.item]] delegate:self];
  [self.connection start];
  
  
//  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:info.item]];
//  AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
//  [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
//    info.totalBytesRead = totalBytesRead;
//    info.totalBytesExpectedToRead = totalBytesExpectedToRead;
//    [self.delegate itemDidUpdate:info];
//  }];
//  [operation start];
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
  self.info.state = ISCacheItemStateFound;
  [self.info closeFile];
  [self.delegate itemDidUpdate:self.info];
}


- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  NSLog(@"connection:didFailWithError:");
}


//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
//                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
//{
//}


@end
