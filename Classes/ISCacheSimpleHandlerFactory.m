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

#import "ISCacheSimpleHandlerFactory.h"
#import "ISCacheExceptions.h"

@interface ISCacheSimpleHandlerFactory ()

@property (nonatomic, strong) Class handlerClass;

@end

@implementation ISCacheSimpleHandlerFactory



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
