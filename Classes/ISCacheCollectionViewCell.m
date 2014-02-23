//
//  ISDownloadsCollectionViewCell.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 16/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISCacheCollectionViewCell.h"

@interface ISCacheCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic) ISCacheItemState state;

@end

@implementation ISCacheCollectionViewCell


- (void)awakeFromNib
{
  [super awakeFromNib];
  self.button.enabled = NO;
  self.state = -1;
}


- (void)drawRect:(CGRect)rect
{
  CGFloat spacing = 4.0;
  CGContextRef context = UIGraphicsGetCurrentContext();
  UIColor *black = [UIColor colorWithRed:0.8
                                   green:0.8f
                                    blue:0.8f
                                   alpha:1.0f];
  CGContextSetStrokeColor(context, CGColorGetComponents([black CGColor]));
  CGContextBeginPath(context);
  CGContextMoveToPoint(context, spacing, CGRectGetHeight(self.bounds));
  CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds) - (2 * spacing), CGRectGetHeight(self.bounds));
  CGContextStrokePath(context);
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
      NSString *title = _cacheItem.userInfo[ISCacheItemDescription];
      if (title) {
        self.label.text = title;
        self.label.textColor = [UIColor darkGrayColor];
      } else {
        self.label.text = @"Untitled item";
        self.label.textColor = [UIColor lightGrayColor];
      }
      [_cacheItem addCacheItemObserver:self options:ISCacheItemObserverOptionsInitial];
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


#pragma mark - ISCacheItemObserver


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

      NSString *duration;
      NSUInteger seconds = self.cacheItem.timeRemainingEstimate;
      if (timeRemainingEstimate > 60*60) {
        NSUInteger hours = floor(seconds/(60*60));
        duration = [NSString stringWithFormat:
                    @"%d hours remaining...",
                    hours];
      } else if (timeRemainingEstimate > 60) {
        NSUInteger minutes = floor(seconds/60);
        duration = [NSString stringWithFormat:
                    @"%d minutes remaining...",
                    minutes];
      } else {
        duration = [NSString stringWithFormat:
                    @"%d seconds remaining...",
                    seconds];
      }
      self.detailLabel.text = duration;
      
    } else {
      self.detailLabel.text = @"Remaining time unknown";
    }
    
  } else if (self.cacheItem.state ==
             ISCacheItemStateFound) {
    
    self.detailLabel.text = @"Download complete";
    
  }
}

@end
