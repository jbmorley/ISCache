/*
 * Copyright (C) 2013-2014 InSeven Limited.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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
