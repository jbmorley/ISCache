//
//  ISCacheItemInfo.m
//  Popcorn
//
//  Created by Jason Barrie Morley on 04/08/2013.
//
//

#import "ISCacheItemInfo.h"

typedef enum {
  ISCacheItemInfoFileStateClosed,
  ISCacheItemInfoFileStateOpen,
} ISCacheItemInfoFileState;

@interface ISCacheItemInfo ()

@property (strong) NSFileHandle *fileHandle;
@property ISCacheItemInfoFileState fileState;

@end

@implementation ISCacheItemInfo

static int kCacheItemVersion = 1;

static NSString *kKeyItem = @"item";
static NSString *kKeyContext = @"context";
static NSString *kKeyUserInfo = @"userInfo";
static NSString *kKeyPath = @"path";
static NSString *kKeyIdentifier = @"identifier";
static NSString *kKeyVersion = @"version";
static NSString *kKeyState = @"state";
static NSString *kKeyTotalBytesRead = @"totalBytesRead";
static NSString *kKeyTotalBytesExpectedToRead = @"totakBytesExpectedToRead";


// Serialization to and from a dictionary.
// A future implementation should probably take advatnage of
// NSCoding.


+ (id)itemInfoWithDictionary:(NSDictionary *)dictionary
{
  return [[self alloc] initWithDictionary:dictionary];
}


- (id)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if (self) {
    
    int version = [dictionary[kKeyVersion] intValue];
    NSAssert(version == kCacheItemVersion,
             @"Unsupported cache item version.");
    
    self.item = dictionary[kKeyItem];
    self.context = dictionary[kKeyContext];
    self.userInfo = dictionary[kKeyUserInfo];
    self.path = dictionary[kKeyPath];
    self.identifier = dictionary[kKeyIdentifier];
    self.state = [dictionary[kKeyState] intValue];
    self.totalBytesRead = [dictionary[kKeyTotalBytesRead] longLongValue];
    self.totalBytesExpectedToRead = [dictionary[kKeyTotalBytesExpectedToRead] longLongValue];
  }
  return self;
}


- (NSDictionary *)dictionary
{
  return
  @{kKeyVersion: @(kCacheItemVersion),
    kKeyItem: self.item,
    kKeyContext: self.context,
    kKeyUserInfo: self.userInfo,
    kKeyPath: self.path,
    kKeyIdentifier: self.identifier,
    kKeyState: @(self.state),
    kKeyTotalBytesRead: @(self.totalBytesRead),
    kKeyTotalBytesExpectedToRead: @(self.totalBytesExpectedToRead)};
}


- (void)openFile
{
  @synchronized(self) {
    if (self.fileState == ISCacheItemInfoFileStateClosed) {
      
      self.fileHandle
      = [NSFileHandle fileHandleForWritingAtPath:self.path];
      if (self.fileHandle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:self.path
                                                contents:nil
                                              attributes:nil];
        self.fileHandle
        = [NSFileHandle fileHandleForWritingAtPath:self.path];
      }
      
      [self.fileHandle seekToEndOfFile];
      self.fileState = ISCacheItemInfoFileStateOpen;
    }
  }
}


- (void)closeFile
{
  @synchronized(self) {
    if (self.fileState == ISCacheItemInfoFileStateOpen) {
      [self.fileHandle closeFile];
      self.fileState = ISCacheItemInfoFileStateClosed;
    }
  }
}


- (void)deleteFile
{
  @synchronized(self) {
    
    // Close the file.
    [self closeFile];
    
    // Delete the file.
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.path
                            error:&error];
    if (error) {
      // TODO Handle an error in deleting the file.
      // What can we actually do here if the file wasn't correctly
      // deleted?
    }

  }
}


- (void)writeDataToFile:(NSData *)data
{
  @synchronized(self) {
    [self openFile];
    [self.fileHandle writeData:data];
  }
}


@end
