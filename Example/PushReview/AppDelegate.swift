//
//  AppDelegate.swift
//  PushReview
//
//  Created by Gasper Kolenc on 03/13/2016.
//  Copyright (c) 2016 Gasper Kolenc. All rights reserved.
//

import UIKit
import PushReview

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Configure PushReview
        PushReview.configureWithAppId("981681897", appDelegate: self)
        PushReview.registerNotificationSettings()
        
        return true
    }
}

