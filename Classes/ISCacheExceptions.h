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

#import <Foundation/Foundation.h>

// ISCache currently throws only a small number of exceptions so
// they are appropriately fine-grained. This may need to change
// as-and-when the codebase grows.

// Names.
static NSString *ISCacheExceptionUnableToCreateItemDirectory = @"ISCacheExceptionUnableToCreateDirectory";
static NSString *ISCacheExceptionExistingFactoryForContext = @"ISCacheExceptionExistingFactoryForContext";
static NSString *ISCacheExceptionMissingFactoryForContext = @"ISCacheExceptionMissingFactoryForContext";
static NSString *ISCacheExceptionUnsupportedCacheStoreVersion = @"ISCacheExceptionUnsupportedCacheStoreVersion";
static NSString *ISCacheExceptionUnsupportedCacheStoreItemVersion =  @"ISCacheExceptionUnsupportedCacheStoreItemVersion";
static NSString *ISCacheExceptionInvalidHandler = @"ISCacheExceptionInvalidHandler";

// Reason.
static NSString *ISCacheExceptionUnableToCreateItemDirectoryReason = @"It was not possible to create the directory for the cache items.";
static NSString *ISCacheExceptionFactoryAlreadyRegisteredReason = @"A cache handler factory has already been registered for the specified protocol.";
static NSString *ISCacheExceptionMissingFactoryForContextReason = @"No cache handler factory has been registered for the specified protocol.";
static NSString *ISCacheExceptionUnsupportedCacheStoreVersionReason = @"The cache store is using an unsupported version.";
static NSString *ISCacheExceptionUnsupportedCacheStoreItemVersionReason =  @"Unable to internalize cache item with unsupported version.";
static NSString *ISCacheExceptionInvalidHandlerReason = @"Cache handlers must respond to the NSCacheHandler protocol.";