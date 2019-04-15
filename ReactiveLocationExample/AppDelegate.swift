//
//  AppDelegate.swift
//  ReactiveLocationExample
//
//  Created by Jakub Olejník on 05/02/2019.
//  Copyright © 2019 Jakub Olejník. All rights reserved.
//

import UIKit
import ReactiveLocation

let reactiveLocation: ReactiveLocationService = { // but do your DI properly ☝️
    let rl = ReactiveLocation { $0.requestWhenInUseAuthorization() }
    rl.isVerbose = true
    return rl
}()

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
