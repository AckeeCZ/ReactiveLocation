#
# Be sure to run `pod lib lint ReactiveLocation.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ReactiveLocation'
  s.version          = '1.0.0'
  s.summary          = 'Simple yet powerful wrapper of CLLocationManager for ReactiveCocoa'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Simple yet powerful wrapper of CLLocationManager for ReactiveCocoa. With support of requestim permissions and obtaiining user's location. Heading, Regions and Visits.
DESC

  s.homepage         = 'https://github.com/AckeeCZ/ReactiveLocation'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ackee' => 'info@ackee.cz' }
  s.source           = { :git => 'https://github.com/<GITHUB_USERNAME>/ReactiveLocation.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'ReactiveLocation/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ReactiveLocation' => ['ReactiveLocation/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ReactiveCocoa'
end
