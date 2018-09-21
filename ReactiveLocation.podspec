Pod::Spec.new do |s|
  s.name             = 'ReactiveLocation'
  s.version          = '3.1.1'
  s.summary          = 'Simple yet powerful wrapper of CLLocationManager for ReactiveCocoa'
  s.description      = <<-DESC
Simple yet powerful wrapper of CLLocationManager for ReactiveCocoa. With support of requestim permissions and obtaiining user's location. Heading, Regions and Visits.
DESC
  s.homepage         = 'https://github.com/AckeeCZ/ReactiveLocation'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ackee' => 'info@ackee.cz' }
  s.source           = { :git => 'https://github.com/AckeeCZ/ReactiveLocation.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.swift_version    = '4.2

  s.source_files = 'ReactiveLocation/*.swift'
  s.dependency 'ReactiveSwift', '~> 4.0''
end
