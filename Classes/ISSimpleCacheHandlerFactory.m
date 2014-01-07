//
//  ISSimpleCacheHandlerFactory.m
//  Pods
//
//  Created by Jason Barrie Morley on 28/12/2013.
//
//

#import "ISSimpleCacheHandlerFactory.h"
#import "ISCacheExceptions.h"

@interface ISSimpleCacheHandlerFactory ()

@property (nonatomic, strong) Class handlerClass;

@end

@implementation ISSimpleCacheHandlerFactory



+ (id)factoryWithClass:(Class)handlerClass
{
  return [[self alloc] initWithClass:handlerClass];
}


- (id)initWithClass:(Class)handlerClass
{
  self = [super init];
  if (self) {
    // Check the class conforms to the correct protocol.
    if (![handlerClass conformsToProtocol:@protocol(ISCacheHandler)]) {
      @throw [NSException exceptionWithName:ISCacheExceptionInvalidHandler
                                     reason:ISCacheExceptionInvalidHandlerReason
                                   userInfo:nil];
    }
    
    self.handlerClass = handlerClass;
  }
  return self;
}


- (id<ISCacheHandler>)createHandler:(NSDictionary *)userInfo
{
  id<ISCacheHandler> handler = [[self.handlerClass alloc] init];
  return handler;
}

@end
