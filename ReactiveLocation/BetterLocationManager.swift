//
//  BetterLocationManager.swift
//  ReactiveLocation
//
//  Created by Jakub Olejník on 05/02/2019.
//  Copyright © 2019 Jakub Olejník. All rights reserved.
//

import CoreLocation

internal final class BetterLocationManager: CLLocationManager {
    private(set) internal var isUpdatingLocation = false
    
    override func startUpdatingLocation() {
        isUpdatingLocation = true
        super.startUpdatingLocation()
    }
    
    override func stopUpdatingLocation() {
        super.stopUpdatingLocation()
        isUpdatingLocation = false
    }
}
