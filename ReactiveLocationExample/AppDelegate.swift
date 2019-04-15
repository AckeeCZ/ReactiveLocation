//
//  AppDelegate.swift
//  ReactiveLocationExample
//
//  Created by Jakub Olejník on 05/02/2019.
//  Copyright © 2019 Jakub Olejník. All rights reserved.
//

import UIKit
import ReactiveLocation

let reactiveLocation = ReactiveLocation { $0.requestWhenInUseAuthorization() } // but do your DI properly ☝️

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        reactiveLocation.isVerbose = true
        return true
    }
}
