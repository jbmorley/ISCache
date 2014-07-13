//
//  ISCacheTests.m
//  ISCacheTests
//
//  Created by Jason Barrie Morley on 13/07/2014.
//
//

#import <XCTest/XCTest.h>
#import <ISCache/ISCache.h>

@interface ISCacheTests : XCTestCase

@property (nonatomic, strong) ISCache *cache;
@property (nonatomic, strong) id<ISCacheFilter> filterStateAll;

@end

static NSString *const kDownloadURL = @"https://upload.wikimedia.org/wikipedia/commons/c/c8/AudreyHepburn_leggings.jpg";

@implementation ISCacheTests

- (void)setUp
{
  [super setUp];
  
  // TODO Create and persist different caches for tests.
  self.cache = [ISCache defaultCache];
  self.filterStateAll = [ISCacheStateFilter filterWithStates:ISCacheItemStateAll];
  
  // Get the existing items.
  NSArray *items = [self.cache items:self.filterStateAll];
  
  // Remove them from the cache.
  [self.cache removeItems:items];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testDefaultCache
{
  ISCache *cache = [ISCache defaultCache];
  XCTAssertNotNil(cache,
                  @"Check default cache construction.");
}

- (void)testCacheEmpty
{
  XCTAssertEqual([[self.cache items:self.filterStateAll] count], 0,
                 @"Check that the initial cache is empty.");
}

- (void)testCacheNonEmpty
{
  [self fetchItem];
  XCTAssertTrue([[self.cache items:self.filterStateAll] count] > 0,
                @"Check that the initial cache is empty.");
}

- (void)testCacheItemNotFound
{
  ISCacheItem *item = [self.cache itemForIdentifier:kDownloadURL
                                            context:ISCacheURLContext
                                        preferences:nil];
  XCTAssertEqual(item.state, ISCacheItemStateNotFound,
                 @"Check the initial state of a missing cache item.");
}

- (void)testCacheItemFetch
{
  ISCacheItem *item = [self fetchItem];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
  XCTAssertEqual(item.state, ISCacheItemStateFound,
                 @"Check that an item downloads successfully.");
}

- (ISCacheItem *)fetchItem
{
  ISCacheItem *item = [self.cache itemForIdentifier:kDownloadURL
                                            context:ISCacheURLContext
                                        preferences:nil];
  [item fetch];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
  return item;
}

- (void)testCacheItemFound
{
  [self fetchItem];
  ISCacheItem *item = [self.cache itemForIdentifier:kDownloadURL
                                            context:ISCacheURLContext
                                        preferences:nil];
  XCTAssertEqual(item.state, ISCacheItemStateFound,
                 @"Check that a previously downloaded item has the correct state.");
}

- (void)testCacheItemFilesCount
{
  [self fetchItem];
  ISCacheItem *item = [self.cache itemForIdentifier:kDownloadURL
                                            context:ISCacheURLContext
                                        preferences:nil];
  XCTAssertEqual([item.files count], 1,
                 @"Check for the correct number of files for a download.");
}

@end
