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

#import "ISCacheFile.h"

@interface ISCacheFile ()

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSString *directory;
@property ISCacheFileState fileState;

@end

@implementation ISCacheFile


- (id)initWithDirectory:(NSString *)directory
               filename:(NSString *)filename
{
  self = [super init];
  if (self) {
    self.directory = directory;
    self.filename = filename;
  }
  return self;
}


- (void)open
{
  if (self.fileState == ISCacheFileStateClosed) {
    
    self.fileHandle
    = [NSFileHandle fileHandleForWritingAtPath:self.path];
    if (self.fileHandle == nil) {
      
      NSFileManager *fileManager = [NSFileManager defaultManager];
      
      // Create the directory if neccessary.
      NSString *parent = [self.path stringByDeletingLastPathComponent];
      BOOL isDirectory;
      NSError *error;
      if (![fileManager fileExistsAtPath:parent
                             isDirectory:&isDirectory]) {
        [fileManager createDirectoryAtPath:parent
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
      }
      
      // Create the file.
      [fileManager createFileAtPath:self.path
                           contents:nil
                         attributes:nil];
      self.fileHandle
      = [NSFileHandle fileHandleForWritingAtPath:self.path];
    }
    
    [self.fileHandle seekToEndOfFile];
    self.fileState = ISCacheFileStateOpen;
  }
}


- (void)close
{
  if (self.fileState == ISCacheFileStateOpen) {
    [self.fileHandle closeFile];
    self.fileState = ISCacheFileStateClosed;
  }
}


- (void)appendData:(NSData *)data
{
  [self open];
  [self.fileHandle writeData:data];
}


- (NSData *)data
{
  [self close];
  return [NSData dataWithContentsOfFile:self.path];
}


- (void)remove
{
  [self close];
  NSError *error;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager removeItemAtPath:self.path
                          error:&error];
  if (error) {
  }
}


- (BOOL)exists
{
  BOOL isDirectory = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [fileManager fileExistsAtPath:self.path
                           isDirectory:&isDirectory];
}


- (NSString *)path
{
  return [self.directory stringByAppendingPathComponent:self.filename];
}


@end
