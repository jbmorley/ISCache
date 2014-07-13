#!/bin/bash

set -e

pushd Tests

pod install
xcodebuild -sdk iphonesimulator7.1 -workspace ISCacheTests.xcworkspace -scheme ISCacheTests test || exit 1

popd