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
static NSString *const kCacheIdentifier = @"test-cache";

@implementation ISCacheTests

- (void)setUp
{
  [super setUp];
  [self purgeCache];
}

- (void)tearDown
{
  [self purgeCache];
  [super tearDown];
}

- (void)purgeCache
{
  self.cache = nil;
  @autoreleasepool {
    ISCache *cache = [ISCache cacheWithIdentifier:kCacheIdentifier];
    BOOL success = [cache purge];
    XCTAssertTrue(success, @"Checking a successful cache purge.");
  }
}

- (void)closeCache
{
  self.cache = nil;
}

- (ISCache *)cache
{
  if (_cache == nil) {
    _cache = [ISCache cacheWithIdentifier:kCacheIdentifier];
  }
  return _cache;
}

// TODO Flesh out the purge API and ensure that caches cannot be left in bad states.

- (void)testCacheCount
{
  @autoreleasepool {
    __attribute__((objc_precise_lifetime))
    ISCacheItem *item = [self.cache itemForIdentifier:kDownloadURL
                                              context:ISCacheURLContext
                                          preferences:@{@"KeyA": @"ValueA",
                                                        @"KeyB": @"ValueB"}];
  }
  XCTAssertEqual([[self.cache allItems] count], 1,
                 @"Check that there is one item in the cache.");
}

// Cache items are expected to persist for the lifetime of the application.
- (void)testCacheItemLifetime
{
  __weak ISCacheItem *weakItem;
  @autoreleasepool {
    __attribute__((objc_precise_lifetime))
    ISCacheItem *item = [self.cache itemForIdentifier:kDownloadURL
                                              context:ISCacheURLContext
                                          preferences:@{@"KeyA": @"ValueA",
                                                        @"KeyB": @"ValueB"}];
    weakItem = item;
  }
  
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  
  ISCacheItem *item = [self.cache itemForIdentifier:kDownloadURL
                                            context:ISCacheURLContext
                                        preferences:@{@"KeyA": @"ValueA",
                                                      @"KeyB": @"ValueB"}];
  XCTAssertEqualObjects(item, weakItem,
                        @"Check that the same item is fetched from the cache during application lifetime.");
}

// TODO Check that we correctly fail when attempting to set non-serializable data in preferences and
// userdict.

// TODO Assert that we do not write to the disk unnecessarily.

// Cache items should persist across different instances of the cache.
- (void)testPersistantStorage
{
  NSDictionary *preferences = @{@"KeyA": @"ValueA",
                                @"KeyB": @"ValueB"};
  NSDictionary *userInfo = @{@"InfoA": @"InfoB"};
  NSString *uid;
  @autoreleasepool {
    __attribute__((objc_precise_lifetime))
    ISCacheItem *item = [self.cache itemForIdentifier:kDownloadURL
                                              context:ISCacheURLContext
                                          preferences:preferences];
    item.userInfo = userInfo;
    uid = item.uid;
  }

  [self closeCache];
  ISCacheItem *item = [self.cache itemForUid:uid];
  
  XCTAssertEqualObjects(item.identifier, kDownloadURL,
                        @"Checking that item identifiers persist across cache instances.");
  XCTAssertEqualObjects(item.context, ISCacheURLContext,
                        @"Checking that item contexts persist across cache instances.");
  XCTAssertEqualObjects(item.preferences, preferences,
                        @"Checking that item preferences persist across cache instances.");
  XCTAssertEqualObjects(item.userInfo, userInfo,
                        @"Checking that item userInfo persist across cache instances.");
}

- (void)testDefaultCacheNotNil
{
  XCTAssertNotNil([ISCache defaultCache],
                  @"Check default cache construction.");
}

- (void)testCacheEmpty
{
  NSArray *items = [self.cache allItems];
  XCTAssertEqual([items count], 0,
                 @"Check that the initial cache is empty (%@).", items);
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
