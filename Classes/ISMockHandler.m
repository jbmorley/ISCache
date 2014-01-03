//
//  ISHTTPHandler.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import "ISMockHandler.h"

@implementation ISMockHandler

- (void)fetchItem:(ISCacheItem *)info
         delegate:(id<ISCacheHandlerDelegate>)delegate
{
  // TODO Is this a reference cycle?
  NSLog(@"Performing fetch!");
  double delayInSeconds = 10.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
    NSLog(@"Dispatching the event...");
    [delegate itemDidUpdate:info];
  });
}

- (void)cancel
{
  NSAssert(NO, @"ISMockHandler does not provde a cancel implementation.");
}

@end
