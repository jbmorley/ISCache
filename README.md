ISCache
=======

Introduction
------------

ISCache is intended to be a transport agnostic way to cache and work with data: it may be desirable to cache files within custom domains such as Google Drive or Dropbox, to generate and cache locally generated thumbnails (e.g. rendering a PDF) or caching data over a completely proprietary mechanism. In order to support this, fetches are performed by objects which implement the `ISCacheHandler` protocol.

Getting Started
---------------

### Items

#### Observing

* providing an `ISCacheBlock` which will receive callbacks during the lifetime of the image fetch
* `ISCacheItem` [key-value observing](https://developer.apple.com/library/mac/documentation/cocoa/conceptual/KeyValueObserving/KeyValueObserving.html)
* implemetning the `ISCacheObserver` protocol and observing `ISCache` by means of `addObserver:` and `removeObserver:`


### Images

ISCache provides a handy UIImage extension for loading images. Image loading are performed using GCD to prevent large images from blocking the UI making it ideal for use in UITableViewCells and UICollectionViewCells:

```objc
#import <ISCache/ISCache.h>

UIImage *placeholder = [UIImage imageNamed:@"placeholder.png"];

[self.imageView setImageWithURL:@"http://www.example.com/image.png"
               placeholderImage:placeholder
                       userInfo:nil
                          block:NULL];
```

Cached images can be resized by providing the resizing settings in the userInfo:

```objc
[self.imageView setImageWithURL:@"http://www.example.com/image.png"
               placeholderImage:placeholder
                       userInfo:@{@"width": @152.0,
                                  @"height": @152.0,
                                  @"scale": @(ISScalingCacheHandlerScaleAspectFill)}
                          block:NULL];
```

#### Cancellation

Repeated calls to `setImageWithURL:placeholderImage:userInfo:completionBlock:` will cancel any previous fetches. Fetches will also be cancelled when the UIImageView is dealloced. Once a fetch is cancelled the `ISCacheBlock` will receive no further updates. If the item fetch has already completed (and the item is in state `ISCacheItemStateFound`) the cancellation will have no effect and the item will remain in the cache.

Fetches can also be explicitly cancelled as follows:

```objc
[self.imageView cancelSetImageWithURL];
```

If you wish to prevent the automatic cancellation of fetches, you can set the following property:

```objc
self.imageView.automaticallyCancelsFetches = NO;
```

### Management and observing

Once an image has been set you are free to manage the item fetch lifecycle using the mechanisms introduced in the previous sections as `setImageWithURL:placeholderImage:userInfo:block` offers the same mechanisms as the more general `fetchItem:context:userInfo:block:`.

For example, a simple image fetch which displays progress and hides and shows the UIProgressView and UIImageView might use the block mechanism as follows:

```objc
// Show the progress view and hide the image view.
self.imageView.hidden = YES;
self.progressView.hidden = NO;

// Set the image.
[self.imageView setImageWithURL:@"http://www.example.com/image.png"
               placeholderImage:placeholder
                       userInfo:nil
                          block:^(ISCacheItem *item) {

                              if (item.state == ISCacheItemStateInProgress) {

                                // Update the progress view.
                                self.progressView.visible = item.progress;

                              } else if (item.state == ISCacheItemStateFound) {

                                // Hide the progress view and show the image view.
                                self.imageView.hidden = NO;
                                self.progressView.hidden = YES;

                              }

                              // Indicate that we still wish to receive updates.
                              return ISCacheBlockStateContinue;

                            }];
```

*A more thorough implementation would also use the `ISCacheItemStateNotFound` state and the `lastError` property to check for unexpected errors or cancellations.*

It is also possible to combine this with direct calls to `ISCache` to determine the cache item state before showing the progress view (to avoid it flickering when the image is already present in the cache):

    // Shared arguments.
    NSString *url = @"http://www.example.com/image.png";
    NSDictionary *userDict = nil;

    // Fetch the current cache item to allow us to inspect its state.
    // It is important to use the same userDict as we will use when setting the image
    // as this is used to identify the item in the cache.
    ISCache *defaultCache = [ISCache defaultCache];
    ISCacheItem *item = [defaultCache item:url
                                   context:ISCacheImageContext
                                  userDict:userDict]

    // Only show the progress view if the item doesn't exist.
    if (item.state == ISCacheItemStateNotFound) {
      self.imageView.hidden = NO;
      self.progressView.hidden = YES;
    } else {
      self.imageView.hidden = YES;
      self.progressView.hidden = NO;
    }

    // Set the image.
    [self.imageView setImageWithURL:url
                   placeholderImage:placeholder
                           userInfo:userInfo
                              block:^(ISCacheItem *item) {
                                  ...
                                }];


Custom handlers
---------------

### Handler lifecycle

Handlers are transient objects; they exist for a single fetch attempt of a cache item.

### Registering a custom handler

In order to provide maximum flexibility, `ISCache` makes use of the factory design pattern for constructing new handlers. `ISCacheSimpleHandlerFactory` is provided as an off-the-shelf factory which will simply alloc-init any class provided so long as it implements the ISCacheHandler protocol. More complex handlers which require non-trivial initialization (e.g. to share state across handlers) will have to implement their own ISCacheHandlerFactory.

While the `ISCacheHTTPHandler` is automatically registered for the `ISCacheURLContext`, the code which does this serves as a good example of how to register your own ISCacheHandlerFactory and ISCacheHandler:

    ISCache *defaultCache = [ISCache defaultCache];

    ISCacheSimpleHandlerFactory *httpFactory = [ISCacheSimpleHandlerFactory
                                                factoryWithClass:[ISCacheHTTPHandler class]];
    [defaultCache registerFactory:httpFactory
                       forContext:ISCacheURLContext];


*This code will actually cause ISCache to throw an exception as you are not allowed to register more than one handler per context.*

### Completion actions

...

Notes
-----

Future
------

Thanks
------


