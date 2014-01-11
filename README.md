ISCache
=======

Introduction
------------

ISCache is intended to be a transport agnostic way to cache and work with data: it may be desirable to cache files within custom domains such as Google Drive or Dropbox, to generate and cache locally generated thumbnails (e.g. rendering a PDF) or caching data over a completely proprietary mechanism. In order to support this, fetches are performed by objects which implement the `ISCacheHandler` protocol.

Getting Started
---------------

### Items



### Images

ISCache provides a handy UIImage extension for loading images. Both fetches and image loading are performed using GCD:

    #import <ISCache/ISCache.h>

    UIImage *placeholder = [UIImage imageNamed:@"placeholder.png"];

    [self.imageView setImageWithURL:@"http://www.example.com/image.png"
                   placeholderImage:placeholder
                         userInfo:nil
                            block:NULL];

Cached images can be resized by providing the resizing settings in the userInfo:

    [self.imageView setImageWithURL:@"http://www.example.com/image.png"
                   placeholderImage:placeholder
                         userInfo:@{@"width": @152.0,
                                    @"height": @152.0,
                                    @"scale": @(ISScalingCacheHandlerScaleAspectFill)}
                            block:NULL];

Repeated calls to `setImageWithURL:placeholderImage:userInfo:completionBlock:` will cancel any previous outstanding fetch. Fetches can also be explicitly cancelled as follows:

    [self.imageView cancelSetImageWithURL];

TODO Write something about how UIImage cache items can be managed.

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


*N.B. This code will actually cause ISCache to throw an exception as you are not allowed to register more than one handler per context.*

### Completion actions

...

Notes
-----

Future
------

Thanks
------


