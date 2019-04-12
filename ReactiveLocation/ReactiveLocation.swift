//
//  ReactiveLocation.swift
//  ReactiveLocation
//
//  Created by Jakub Olejník on 05/02/2019.
//  Copyright © 2019 Jakub Olejník. All rights reserved.
//

import Result
import CoreLocation
import ReactiveSwift

public protocol ReactiveLocationService {
    var locationManager: CLLocationManager { get }
    
    func locationProducer() -> SignalProducer<CLLocation, NoError>
}

public final class ReactiveLocation: NSObject, ReactiveLocationService, CLLocationManagerDelegate {
    public static let shared = ReactiveLocation()
    
    public var locationManager: CLLocationManager { return _locationManager }
    public var isVerbose = false
    public var requestPermission: (CLLocationManager) -> () = { _ in }
    
    private let _locationManager: BetterLocationManager
    private let observerLock = NSLock()
    
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
    
    private var isAuthorized: Bool {
        let status = CLLocationManager.authorizationStatus()
        return status  == .authorizedAlways || status == .authorizedWhenInUse
    }
    
    private let (locationSignal, locationObserver) = Signal<CLLocation, NoError>.pipe()
    
    // MARK: - Initializers
    
    public override init() {
        _locationManager = BetterLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Public interface
    
    public func locationProducer() -> SignalProducer<CLLocation, NoError> {
        let currentValueProducer = SignalProducer(value: locationManager.location).skipNil()
        return currentValueProducer
            .then(requestPermissionProducer())
            .then(SignalProducer(locationSignal))
            .on(started: { [weak self] in self?.observerCount += 1 },
                terminated: { [weak self] in self?.observerCount -= 1 })
    }
    
    // MARK: - CLLocationManager delegate
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { locationObserver.send(value: $0) }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if isAuthorized && observerCount > 0 {
            manager.startUpdatingLocation()
        }
    }
    
    // MARK: - Private helpers
    
    private func requestPermissionProducer() -> SignalProducer<Void, NoError> {
        return SignalProducer { [weak self] observer, _ in
            guard CLLocationManager.authorizationStatus() == .notDetermined, let locationManager = self?.locationManager else {
                observer.send(value: ())
                observer.sendCompleted()
                return
            }
            
            self?.requestPermission(locationManager)
            observer.send(value: ())
            observer.sendCompleted()
        }
    }
}
