Pod::Spec.new do |s|

  s.name         = "ISCache"
  s.version      = "0.0.1"
  s.summary      = "Pluggable Objective-C cache framework"
  s.homepage     = "https://github.com/jbmorley/ISCache"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Jason Barrie Morley" => "jason.morley@inseven.co.uk" }
  s.source       = { :git => "https://github.com/jbmorley/ISCache.git", :commit => "887caf12b1ecd653fcfcb05da43e74c054a758ce" }

  s.source_files = 'Classes/*.{h,m}'

  s.private_header_files = "Classes/*Private.h"

  s.requires_arc = true

  s.platform = :ios, "6.0"

  s.dependency 'NSString-Hashes', '~> 1.2.1'
  s.dependency 'ISUtilities'
  s.dependency 'AFNetworking', '~> 2.0'


end
