![](http://img.ack.ee/default/image/test/ios_reactivelocation_logo.png)  
[![Travis branch](https://img.shields.io/travis/AckeeCZ/ReactiveLocation/master.svg?maxAge=2592000)](https://travis-ci.org/AckeeCZ/ReactiveLocation)
[![Version](https://img.shields.io/cocoapods/v/ReactiveLocation.svg?style=flat)](http://cocoapods.org/pods/ReactiveLocation)
[![License](https://img.shields.io/cocoapods/l/ReactiveLocation.svg?style=flat)](http://cocoapods.org/pods/ReactiveLocation)
[![Platform](https://img.shields.io/cocoapods/p/ReactiveLocation.svg?style=flat)](http://cocoapods.org/pods/ReactiveLocation)

## ReactiveCocoa wrapper for CLLocationManager.

Our wrapper supports almost all operations on CLLocationManager. With factory method you can easily set up manager for your needs. By default we just set the desiredAccuracy on Best. You can even request for users permission with Action. Mocking support for tests via Protocol imeplemtation.

### Available methods
```swift
static func locationProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLLocation, LocationError>
static func singleLocationProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLLocation, LocationError>
static func visitProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLVisit, LocationError>
static func regionProducer(_ region: CLRegion, managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<RegionEvent, LocationError>
static func headingProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLHeading, LocationError>
static var authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> { get }
```

Difference versus location and singleLocation lies in ios9+ implementation of CLLocationManager's method `requestLocation` which takes care of the unneccesary logic and gets you just one precise location of the user. Producer itself holds strong reference on its own CLLocationManager so as long as Producer/Signal closure is alive so is its manager.

### Example Usage
Simply retrieve user's current location

```swift
ReactiveLocation.singleLocationProducer.startWithNext { location in
    print(location)            
}
```

Simply retrieve location over time. With custom manager settings

```swift
ReactiveLocation.singleLocationProducer { manager in
	manager.distanceFilter = 1000
	manager.desiredAccuracy = kCLLocationAccuracyBest
}.startWithNext { location in
    print(location)            
}
```

Request user for WhenInUse permissions with result

```swift
ReactiveLocation.authorizeAction.apply(.WhenInUse).producer.startWithNext { (status) in
	print("Current user permission status on WhenInUse is \(status)")
}
```

## Testing Support

`ReactiveLocation` conforms to `ReactiveLocationService` protocol. So if you would like to mock your own location and test functionality you can just Create your own MockImplementation that conforms to this protocol



## Example

In progresss

## Requirements

ReactiveCocoa

## Installation

ReactiveLocation is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "ReactiveLocation"
```

## Author

Ackee.cz (www.ackee.cz)

## License

ReactiveLocation is available under the MIT license. See the LICENSE file for more info.
