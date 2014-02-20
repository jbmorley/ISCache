//
//  ISDownloadsCollectionViewCell.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 16/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISDownloadsCollectionViewCell.h"

@interface ISDownloadsCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic) ISCacheItemState state;

@end

@implementation ISDownloadsCollectionViewCell


- (void)awakeFromNib
{
  [super awakeFromNib];
  self.button.enabled = NO;
  self.state = -1;
}


- (void)dealloc
{
  [self.cacheItem removeCacheItemObserver:self];
}


- (void)setCacheItem:(ISCacheItem *)cacheItem
{
  if (_cacheItem != cacheItem) {
    [_cacheItem removeCacheItemObserver:self];
    _cacheItem = cacheItem;
    if (_cacheItem) {
      self.button.enabled = YES;
      // TODO Use a formal description.
      NSString *title = _cacheItem.userInfo[@"name"];
      if (title) {
        self.label.text = title;
        self.label.textColor = [UIColor darkGrayColor];
      } else {
        self.label.text = @"Untitled item";
        self.label.textColor = [UIColor lightGrayColor];
      }
      [_cacheItem addCacheItemObserver:self
                               options:ISCacheItemObserverOptionsInitial];
    }
  }
}


- (void)setState:(ISCacheItemState)state
{
  if (_state != state) {
    _state = state;
    
    if (_state == ISCacheItemStateInProgress) {
      UIImage *image = [UIImage imageNamed:@"ISCache.bundle/stop.png"];
      [self.button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                   forState:UIControlStateNormal];
      self.button.enabled = YES;
    } else if (_state == ISCacheItemStateNotFound) {
      UIImage *image = [UIImage imageNamed:@"ISCache.bundle/refresh.png"];
      [self.button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                   forState:UIControlStateNormal];
      self.button.enabled = YES;
    } else if (_state == ISCacheItemStateFound) {
      UIImage *image = [UIImage imageNamed:@"ISCache.bundle/trash.png"];
      [self.button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                   forState:UIControlStateNormal];
      self.button.enabled = YES;
    }
    
    [UIView animateWithDuration:0.3
                     animations:
     ^{
       if (_state ==
           ISCacheItemStateInProgress) {
         self.backgroundColor =
         [UIColor colorWithWhite:0.95
                           alpha:1.0];
       } else if (_state ==
                  ISCacheItemStateNotFound) {
         self.backgroundColor =
         [UIColor colorWithWhite:0.93
                           alpha:1.0];
       } else if (_state ==
                  ISCacheItemStateFound) {
         self.backgroundColor =
         [UIColor colorWithWhite:0.98
                           alpha:1.0];
       }
     }];
  }
}


- (void)cacheItemDidChange:(ISCacheItem *)cacheItem
{
  self.state = self.cacheItem.state;
  self.progressView.progress = self.cacheItem.progress;
  
  if (self.cacheItem.state ==
      ISCacheItemStateNotFound) {
    
    if (self.cacheItem.lastError) {
      if (self.cacheItem.lastError.domain ==
          ISCacheErrorDomain &&
          self.cacheItem.lastError.code ==
          ISCacheErrorCancelled) {
        self.detailLabel.text = @"Download cancelled";
      } else {
        self.detailLabel.text = @"Download failed";
      }
    } else {
      self.detailLabel.text = @"Download missing";
    }
  
  } else if (self.cacheItem.state ==
             ISCacheItemStateInProgress) {
    
    NSTimeInterval timeRemainingEstimate = self.cacheItem.timeRemainingEstimate;
    if (timeRemainingEstimate != 0) {
      self.detailLabel.text = [NSString stringWithFormat:
                               @"%d seconds remaining...",
                               (int)self.cacheItem.timeRemainingEstimate];
    } else {
      self.detailLabel.text = @"Remaining time unknown";
    }
    
  } else if (self.cacheItem.state ==
             ISCacheItemStateFound) {
    
    self.detailLabel.text = @"Download complete";
    
  }
}


- (IBAction)buttonClicked:(id)sender
{
  if (self.cacheItem) {
    
    if (self.cacheItem.state ==
        ISCacheItemStateInProgress) {
      
      [self.cacheItem cancel];
      
    } else if (self.cacheItem.state ==
               ISCacheItemStateNotFound) {
      
      [self.cacheItem fetch];
      
    } else if (self.cacheItem.state ==
               ISCacheItemStateFound) {
      
      [self.cacheItem remove];
      
    }
  }
}


@end
