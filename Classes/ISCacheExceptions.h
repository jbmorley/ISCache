//
//  ISCacheExceptions.h
//  Pods
//
//  Created by Jason Barrie Morley on 07/01/2014.
//
//

#import <Foundation/Foundation.h>

// ISCache currently throws only a small number of exceptions so
// they are appropriately fine-grained. This may need to change
// as-and-when the codebase grows.

// Names.
static NSString *ISCacheExceptionExistingFactoryForContext = @"ISCacheExceptionExistingFactoryForContext";
static NSString *ISCacheExceptionMissingFactoryForContext = @"ISCacheExceptionMissingFactoryForContext";
static NSString *ISCacheExceptionUnsupportedCacheStoreVersion = @"ISCacheExceptionUnsupportedCacheStoreVersion";
static NSString *ISCacheExceptionInvalidHandler = @"ISCacheExceptionInvalidHandler";

// Reason.
static NSString *ISCacheExceptionFactoryAlreadyRegisteredReason = @"A cache handler factory has already been registered for the specified protocol.";
static NSString *ISCacheExceptionMissingFactoryForContextReason = @"No cache handler factory has been registered for the specified protocol.";
static NSString *ISCacheExceptionUnsupportedCacheStoreVersionReason = @"The cache store is using an unsupported version.";
static NSString *ISCacheExceptionInvalidHandlerReason = @"Cache handlers must respond to the NSCacheHandler protocol.";