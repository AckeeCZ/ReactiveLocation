![](http://img.ack.ee/default/image/test/ios_reactivelocation_logo.png)  
[![Travis branch](https://img.shields.io/travis/AckeeCZ/ReactiveLocation/master.svg)](https://travis-ci.org/AckeeCZ/ReactiveLocation)
[![Version](https://img.shields.io/cocoapods/v/ReactiveLocation.svg?style=flat)](http://cocoapods.org/pods/ReactiveLocation)
[![License](https://img.shields.io/cocoapods/l/ReactiveLocation.svg?style=flat)](http://cocoapods.org/pods/ReactiveLocation)
[![Platform](https://img.shields.io/cocoapods/p/ReactiveLocation.svg?style=flat)](http://cocoapods.org/pods/ReactiveLocation)

## ReactiveSwift wrapper for CLLocationManager.

Our wrapper supports almost all operations on CLLocationManager. With factory method you can easily set up manager for your needs. By default we just set the desiredAccuracy on Best. You can even request for users permission with Action. Mocking support for tests via Protocol implementation.

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
ReactiveLocation.locationProducer().startWithResult {
    switch $0 {
    case let .success(location):
        print(location)
    case let .failure(error):
        print(error)
    }
}
```

Simply retrieve location over time. With custom manager settings

```swift
ReactiveLocation.singleLocationProducer { manager in
    manager.distanceFilter = 1000
    manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    .startWithResult {
        switch $0 {
        case let .success(location):
            print(location)
        case let .failure(error):
            print(error)
        }
}
```

Request user for WhenInUse permissions with result

```swift
ReactiveLocation.authorizeAction.apply(.whenInUse).startWithResult {
    switch $0 {
    case let .success(status):
        print("Current user permission status on WhenInUse is \(status)")
    case let .failure(error):
        print(error)
    }
}
```

## Testing Support

`ReactiveLocation` conforms to `ReactiveLocationService` protocol. So if you would like to mock your own location and test functionality you can just Create your own MockImplementation that conforms to this protocol



## Example

In progresss

## Requirements

ReactiveSwift

## Installation

ReactiveLocation is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "ReactiveLocation"
```

### Version compatibility

ReactiveLocation requires Xcode 8+ and Swift 3. Older versions are supported in previous versions.

| Swift Version | ReactiveLocationVersion |
| ------------- | ------ |
| 3.X           | master |
| 2.X           | 1.0 |


## Forking this repository
If you use ReactiveLocation in your projects drop us a tweet at [@ackeecz][1] or leave a star here on Github. We would love to hear about it!

## Sharing is caring
This tool and repo has been opensourced within our `#sharingiscaring` action when we have decided to opensource our internal projects

## Author

[Ackee](www.ackee.cz) team

## License

ReactiveLocation is available under the MIT license. See the LICENSE file for more info.

[1]:	https://twitter.com/AckeeCZ
