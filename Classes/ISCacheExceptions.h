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

#import <Foundation/Foundation.h>

// ISCache currently throws only a small number of exceptions so
// they are appropriately fine-grained. This may need to change
// as-and-when the codebase grows.

// Names.
static NSString *ISCacheExceptionUnableToCreateItemDirectory = @"ISCacheExceptionUnableToCreateDirectory";
static NSString *ISCacheExceptionUnableToSaveStore = @"ISCacheExceptionUnableToSaveStore";
static NSString *ISCacheExceptionExistingFactoryForContext = @"ISCacheExceptionExistingFactoryForContext";
static NSString *ISCacheExceptionMissingFactoryForContext = @"ISCacheExceptionMissingFactoryForContext";
static NSString *ISCacheExceptionUnsupportedCacheStoreVersion = @"ISCacheExceptionUnsupportedCacheStoreVersion";
static NSString *ISCacheExceptionUnsupportedCacheStoreItemVersion =  @"ISCacheExceptionUnsupportedCacheStoreItemVersion";
static NSString *ISCacheExceptionInvalidHandler = @"ISCacheExceptionInvalidHandler";

// Reason.
static NSString *ISCacheExceptionUnableToCreateItemDirectoryReason = @"It was not possible to create the directory for the cache items.";
static NSString *ISCacheExceptionUnableToSaveStoreReason = @"Unable to write the cache store to file.";
static NSString *ISCacheExceptionFactoryAlreadyRegisteredReason = @"A cache handler factory has already been registered for the specified protocol.";
static NSString *ISCacheExceptionMissingFactoryForContextReason = @"No cache handler factory has been registered for the specified protocol.";
static NSString *ISCacheExceptionUnsupportedCacheStoreVersionReason = @"The cache store is using an unsupported version.";
static NSString *ISCacheExceptionUnsupportedCacheStoreItemVersionReason =  @"Unable to internalize cache item with unsupported version.";
static NSString *ISCacheExceptionInvalidHandlerReason = @"Cache handlers must respond to the NSCacheHandler protocol.";