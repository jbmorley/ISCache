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

#import "ISCacheCompoundFilter.h"

typedef enum {
  ISCacheCompoundFilterModeAND,
  ISCacheCompoundFilterModeOR,
} ISCacheCompoundFilterMode;

@interface ISCacheCompoundFilter ()

@property (nonatomic, strong) id<ISCacheFilter> filterA;
@property (nonatomic, strong) id<ISCacheFilter> filterB;
@property (nonatomic, assign) ISCacheCompoundFilterMode mode;

@end

@implementation ISCacheCompoundFilter

+ (id)filterMatching:(id<ISCacheFilter>)filterA
                 and:(id<ISCacheFilter>)filterB
{
  return [[self alloc] initMatching:filterA
                                and:filterB];
}

+ (id)filterMatching:(id<ISCacheFilter>)filterA
                  or:(id<ISCacheFilter>)filterB
{
  return [[self alloc] initMatching:filterA
                                 or:filterB];
}

- (id)initMatching:(id<ISCacheFilter>)filterA
               and:(id<ISCacheFilter>)filterB
{
  self = [super init];
  if (self) {
    self.mode = ISCacheCompoundFilterModeAND;
    self.filterA = filterA;
    self.filterB = filterB;
  }
  return self;
}

- (id)initMatching:(id<ISCacheFilter>)filterA
                or:(id<ISCacheFilter>)filterB
{
  self = [super init];
  if (self) {
    self.mode = ISCacheCompoundFilterModeOR;
    self.filterA = filterA;
    self.filterB = filterB;
  }
  return self;
}

- (BOOL)matchesFilter:(ISCacheItem *)item
{
  if (self.mode == ISCacheCompoundFilterModeAND) {
    return ([self.filterA matchesFilter:item] &&
            [self.filterB matchesFilter:item]);
  } else if (self.mode == ISCacheCompoundFilterModeOR) {
    return ([self.filterA matchesFilter:item] ||
            [self.filterB matchesFilter:item]);
  }
  return NO;
}

- (ISCacheCompoundFilter *)and:(id<ISCacheFilter>)filter
{
  return [ISCacheCompoundFilter filterMatching:self
                                           and:filter];
}


- (ISCacheCompoundFilter *)or:(id<ISCacheFilter>)filter
{
  return [ISCacheCompoundFilter filterMatching:self
                                            or:filter];
}

@end
