//
//  ViewController.swift
//  PushReview
//
//  Created by Gasper Kolenc on 03/13/2016.
//  Copyright (c) 2016 Gasper Kolenc. All rights reserved.
//

import UIKit
import PushReview

class ViewController: UIViewController {
    
    /// Returns true if app is running on simulator
    var isSimulator: Bool {
        return UIDevice.currentDevice().name.hasSuffix("Simulator")
    }
    
    override func viewDidAppear(animated: Bool) {
        if isSimulator {
            let alertController = UIAlertController(title: "Whoopsie!", message: "Please don't use a simulator to test this. You need to use a real device to test notifications", preferredStyle: .Alert)
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    /**
     Schedule a review notification in 10 seconds.
     */
    @IBAction func scheduleNotification(sender: AnyObject) {
        PushReview.timeBeforePresentingWhenAppEntersBackground = 10
        PushReview.timeBeforeReminding = 10
        PushReview.scheduleReviewNotification()
    }
}

