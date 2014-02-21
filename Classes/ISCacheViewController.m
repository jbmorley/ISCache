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

#import "ISCacheViewController.h"
#import "ISCacheCollectionViewCell.h"
#import "ISRotatingFlowLayout.h"
#import <ISUtilities/ISDevice.h>
#import "ISCacheFile.h"
#import "ISCacheStateFilter.h"
#import "ISCacheUserInfoFilter.h"

@interface ISCacheViewController ()

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;
@property (nonatomic, strong) ISRotatingFlowLayout *flowLayout;
@property (nonatomic, strong) id<ISCacheFilter> filter;

@end

static NSString *kCacheCollectionViewCellReuseIdentifier = @"CacheCell";

@implementation ISCacheViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.filter = [ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress];
  self.filter = [[ISCacheUserInfoFilter alloc] initWithUserInfo:@{@"type": @"video"}];
  
  self.title = @"Downloads";
  
  // Create and configure the flow layout.
  self.flowLayout = [ISRotatingFlowLayout new];
  self.flowLayout.adjustsItemSize = YES;
  self.flowLayout.spacing = 2.0f;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    self.flowLayout.minimumItemSize = CGSizeMake(283.0, 72.0);
  } else {
    self.flowLayout.minimumItemSize = CGSizeMake(283.0, 72.0);
  }
  
  self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.flowLayout];
  self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.collectionView.alwaysBounceVertical = YES;
  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;
  [self.view addSubview:self.collectionView];
  
  self.collectionView.backgroundColor = [UIColor whiteColor];
  
  self.adapter = [[ISListViewAdapter alloc] initWithDataSource:self];
  self.connector = [ISListViewAdapterConnector connectorWithCollectionView:self.collectionView];
  [self.adapter addAdapterObserver:self.connector];
  
  // Register the download cell.
  NSBundle* bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"ISCache" withExtension:@"bundle"]];
  UINib *nib = [UINib nibWithNibName:@"ISCacheCollectionViewCell"
                              bundle:bundle];
  [self.collectionView registerNib:nib
        forCellWithReuseIdentifier:kCacheCollectionViewCellReuseIdentifier];
  
  // Buttons.
//  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClicked:)];
//  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel All" style:UIBarButtonItemStylePlain target:self action:@selector(cancelClicked:)];
  
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[ISCache defaultCache] addCacheObserver:self];
  [self.adapter invalidate];
}


- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [[ISCache defaultCache] removeCacheObserver:self];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (IBAction)cancelClicked:(id)sender
{
  ISCache *defaultCache = [ISCache defaultCache];
  NSArray *items = [defaultCache items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]];
  [defaultCache cancelItems:items];
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.adapter.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ISCacheCollectionViewCell *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kCacheCollectionViewCellReuseIdentifier forIndexPath:indexPath];

  ISListViewAdapterItem *item = [self.adapter itemForIndex:indexPath.item];
  [item fetch:^(ISCacheItem *item) {
    
    // Re-fetch the cell.
    ISCacheCollectionViewCell *cell = (ISCacheCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
      cell.cacheItem = item;
    }
    
  }];
  
  return cell;
}


#pragma mark - ISListViewAdapterDataSource


- (void)itemsForAdapter:(ISListViewAdapter *)adapter
        completionBlock:(ISListViewAdapterBlock)completionBlock
{
  ISCache *defaultCache = [ISCache defaultCache];
  NSArray *items = [defaultCache items:self.filter];
  completionBlock(items);
}


- (id)adapter:(ISListViewAdapter *)adapter
identifierForItem:(id)item
{
  ISCacheItem *cacheItem = item;
  return cacheItem.uid;
}


- (id)adapter:(ISListViewAdapter *)adapter
summaryForItem:(id)item
{
  return @"";
}


- (void)adapter:(ISListViewAdapter *)adapter
itemForIdentifier:(id)identifier
completionBlock:(ISListViewAdapterBlock)completionBlock
{
  ISCache *defaultCache = [ISCache defaultCache];
  completionBlock([defaultCache itemForUid:identifier]);
}


#pragma mark - ISCacheObserver


- (void)cacheDidUpdate:(ISCache *)cache
{
  [self.adapter invalidate];
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  ISListViewAdapterItem *item =
  [self.adapter itemForIndex:indexPath.item];
  [item fetch:^(ISCacheItem *item) {
    [self.delegate cacheViewController:self
                    didSelectCacheItem:item];
  }];
}

@end
