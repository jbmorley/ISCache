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

#import "ISCacheContextFilter.h"

// Names.
NSString *const ISCacheExceptionUnableToCreateItemDirectory = @"ISCacheExceptionUnableToCreateDirectory";
NSString *const ISCacheExceptionUnableToSaveStore = @"ISCacheExceptionUnableToSaveStore";
NSString *const ISCacheExceptionExistingFactoryForContext = @"ISCacheExceptionExistingFactoryForContext";
NSString *const ISCacheExceptionMissingFactoryForContext = @"ISCacheExceptionMissingFactoryForContext";
NSString *const ISCacheExceptionUnsupportedCacheStoreVersion = @"ISCacheExceptionUnsupportedCacheStoreVersion";
NSString *const ISCacheExceptionUnsupportedCacheStoreItemVersion =  @"ISCacheExceptionUnsupportedCacheStoreItemVersion";
NSString *const ISCacheExceptionInvalidHandler = @"ISCacheExceptionInvalidHandler";

// Reason.
NSString *const ISCacheExceptionUnableToCreateItemDirectoryReason = @"It was not possible to create the directory for the cache items.";
NSString *const ISCacheExceptionUnableToSaveStoreReason = @"Unable to write the cache store to file.";
NSString *const ISCacheExceptionFactoryAlreadyRegisteredReason = @"A cache handler factory has already been registered for the specified protocol.";
NSString *const ISCacheExceptionMissingFactoryForContextReason = @"No cache handler factory has been registered for the specified protocol.";
NSString *const ISCacheExceptionUnsupportedCacheStoreVersionReason = @"The cache store is using an unsupported version.";
NSString *const ISCacheExceptionUnsupportedCacheStoreItemVersionReason =  @"Unable to internalize cache item with unsupported version.";
NSString *const ISCacheExceptionInvalidHandlerReason = @"Cache handlers must respond to the NSCacheHandler protocol.";
