//
//  LocationViewController.swift
//  ReactiveLocationExample
//
//  Created by Jakub Olejník on 05/02/2019.
//  Copyright © 2019 Jakub Olejník. All rights reserved.
//

import UIKit
import CoreLocation
import ReactiveCocoa
import ReactiveSwift
import ReactiveLocation

final class LocationViewController: UIViewController {
    @IBOutlet weak var locationLabel: UILabel!
    
    // MARK: -  View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBindings()
    }
    
    // MARK: - Private helpers
    
    private func setupBindings() {
        let coordinate = ReactiveLocation.shared.locationProducer()
            .map { $0.coordinate }
        
        locationLabel.reactive.text <~ coordinate.map { String($0.latitude) + "," + String($0.longitude) }
    }
}

