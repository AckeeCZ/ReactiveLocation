//
//  ReactiveLocation.swift
//  ReactiveLocation
//
//  Created by Jakub Olejník on 05/02/2019.
//  Copyright © 2019 Jakub Olejník. All rights reserved.
//

import CoreLocation
import ReactiveSwift

public protocol ReactiveLocationService {
    var locationManager: CLLocationManager { get }
    
    /// Receive location updates
    func locationProducer() -> SignalProducer<CLLocation, Never>
    
    /// Receive single location or nil if it is not available within `timeout`
    func singleLocation(timeout: TimeInterval) -> SignalProducer<CLLocation?, Never>
}

public final class ReactiveLocation: NSObject, ReactiveLocationService, CLLocationManagerDelegate {
    public typealias RequestPermissionCallback = (CLLocationManager) -> ()
    
    public var locationManager: CLLocationManager { return _locationManager }
    public var isVerbose = false
    
    private let _locationManager: BetterLocationManager
    private let observerLock = NSLock()
    private let requestPermission: RequestPermissionCallback
    
    private var observerCount = 0 {
        didSet {
            observerLock.lock()
            
            if isVerbose {
                print("[ReactiveLocation]", "Observer count changed:", observerCount)
            }
            
            if observerCount == 0 {
                if isVerbose {
                    print("[ReactiveLocation]", "Stopping location manager")
                }
                
                locationManager.stopUpdatingLocation()
            } else if isAuthorized && !_locationManager.isUpdatingLocation {
                if isVerbose {
                    print("[ReactiveLocation]", "Starting location manager")
                }
                
                locationManager.startUpdatingLocation()
            }
            observerLock.unlock()
        }
    }
    
    private let (authorizationStatusSignal, authorizationStatusObserver) = Signal<CLAuthorizationStatus, Never>.pipe()
    private lazy var authorizationStatus = Property<CLAuthorizationStatus>(initial: CLLocationManager.authorizationStatus(), then: authorizationStatusSignal)
    
    private var isAuthorized: Bool {
        let status = CLLocationManager.authorizationStatus()
        return status  == .authorizedAlways || status == .authorizedWhenInUse
    }
    
    private let (locationSignal, locationObserver) = Signal<CLLocation, Never>.pipe()
    
    // MARK: - Initializers
    
    public init(requestPermission rp: @escaping RequestPermissionCallback) {
        _locationManager = BetterLocationManager()
        requestPermission = rp
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Public interface
    
    public func locationProducer() -> SignalProducer<CLLocation, Never> {
        let currentValueProducer = SignalProducer(value: locationManager.location).skipNil()
        
        return requestPermissionProducer()
            .then(currentValueProducer)
            .concat(SignalProducer(locationSignal))
            .on(
                started: { [weak self] in self?.observerCount += 1 },
                terminated: { [weak self] in self?.observerCount -= 1 }
            )
    }
    
    public func singleLocation(timeout: TimeInterval) -> SignalProducer<CLLocation?, Never> {
        // most recent known location
        let currentValueProducer = SignalProducer(value: locationManager.location)
        
        // new location from location update or nil after timeout
        let newValueProducer = SignalProducer(locationSignal)
            .map { Optional($0) }
            .take(first: 1)
            .timeout(after: timeout, raising: NSError(domain: "ReactiveLocation", code: 0, userInfo: nil), on: QueueScheduler())
            .flatMapError { _ in SignalProducer<CLLocation?, Never>(value: nil) }
        
        return requestPermissionProducer() // ask for permissions
            .then(SignalProducer.combineLatest(currentValueProducer, newValueProducer)) // wait for current and new value
            .map { $1 ?? $0 } // use new value if available, otherwise use current one
            .on(
                started: { [weak self] in self?.observerCount += 1 },
                terminated: { [weak self] in self?.observerCount -= 1 }
            )
    }
    
    // MARK: - CLLocationManager delegate
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { locationObserver.send(value: $0) }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatusObserver.send(value: status)
        if isAuthorized && observerCount > 0 {
            manager.startUpdatingLocation()
        }
    }
    
    // MARK: - Private helpers
    
    private func requestPermissionProducer() -> SignalProducer<Void, Never> {
        requestPermission(locationManager)
        
        return authorizationStatus.producer
            .filter { $0 != .notDetermined }
            .take(first: 1)
            .map { _ in }
    }
}
