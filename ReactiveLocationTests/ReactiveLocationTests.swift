//
//  ReactiveLocationTests.swift
//  ReactiveLocationTests
//
//  Created by Jakub Olejník on 27/12/2017.
//

import XCTest
import CoreLocation
import ReactiveSwift
@testable import ReactiveLocation

final class ReactiveLocationTimeoutTests: XCTestCase {
    func testLocationTimeouts() {
        let location = ReactiveLocationNever()
        
        async(timeout: 2) { expectation in
            location.locationProducer(timeout: 1).flatMapError { _ in .empty }
                .startWithValues {
                    XCTAssertNil($0)
                    expectation.fulfill()
            }
        }
    }
    
    func testSingleLocationTimeouts() {
        let location = ReactiveLocationNever()
        
        async(timeout: 2) { expectation in
            location.singleLocationProducer(timeout: 1).flatMapError { _ in .empty }
                .startWithValues {
                    XCTAssertNil($0)
                    expectation.fulfill()
            }
        }
    }
    
    func testLocationTimeoutSendsValue() {
        let location = ReactiveLocationZero()
        
        async(timeout: 2) { expectation in
            location.locationProducer(timeout: 1).flatMapError { _ in .empty }
                .startWithValues {
                    XCTAssertEqual($0, location.location)
                    expectation.fulfill()
            }
        }
    }
    
    func testSingleLocationTimeoutSendsValue() {
        let location = ReactiveLocationZero()
        
        async(timeout: 2) { expectation in
            location.singleLocationProducer(timeout: 1).flatMapError { _ in .empty }
                .startWithValues {
                    XCTAssertEqual($0, location.location)
                    expectation.fulfill()
            }
        }
    }
}

private final class ReactiveLocationNever: ReactiveLocationService {
    var authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> = Action { SignalProducer(value: $0) }
    
    func locationProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLLocation, LocationError> {
        return .never
    }
    
    func singleLocationProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLLocation, LocationError> {
        return .never
    }
    
    func visitProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLVisit, LocationError> {
        return .never
    }
    
    func regionProducer(_ region: CLRegion, managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<RegionEvent, LocationError> {
        return .never
    }
    
    func headingProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLHeading, LocationError> {
        return .never
    }
}

private final class ReactiveLocationZero: ReactiveLocationService {
    let location = CLLocation(latitude: 0, longitude: 0)
    
    var authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> = Action { SignalProducer(value: $0) }
    
    func locationProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLLocation, LocationError> {
        return SignalProducer(value: location)
    }
    
    func singleLocationProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLLocation, LocationError> {
        return SignalProducer(value: location)
    }
    
    func visitProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLVisit, LocationError> {
        return .never
    }
    
    func regionProducer(_ region: CLRegion, managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<RegionEvent, LocationError> {
        return .never
    }
    
    func headingProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLHeading, LocationError> {
        return .never
    }
}
