Pod::Spec.new do |s|

  s.name         = "ISCache"
  s.version      = "0.0.1"
  s.summary      = "Pluggable Objective-C cache framework"
  s.homepage     = "https://github.com/jbmorley/ISCache"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Jason Barrie Morley" => "jason.morley@inseven.co.uk" }
  s.source       = { :git => "https://github.com/jbmorley/ISCache.git", :commit => "9e5284fb215fcbcd668dc0736306fde7214b20fc" }

  s.source_files = 'Classes/*.{h,m}'

  s.private_header_files = "Classes/*Private.h"

  s.ios.resource_bundle = { 'ISCache' => 'Resources/*.{xib,png}' }

  s.requires_arc = true

  s.platform = :ios, "6.0", :osx, "10.8"

  s.dependency 'NSString-Hashes', '~> 1.2.1'

end
