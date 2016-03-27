//
//  PushReview.swift
//  PushReview
//
//  Created by Gasper Kolenc on 01/03/16.
//  Copyright © 2016 Gasper Kolenc. All rights reserved.
//

import Foundation
import UIKit

/**
 Notification action keys

    - Review: User wants to review the app so open up the App Store
    - Later: User wants to be reminded about reviewing this app later
    - ReviewCategory: Notification category containing `PushReview` actions
    - Category: Notification payload key for categories
 */
private struct Notification {
    static let Review   = "pushReview_Review"
    static let Later    = "pushReview_Later"
    static let ReviewCategory = "pushReview_Category"
    static let Category = "category"
}

/**
 Keys used for `NSUserDefaults`
 
    - AppStarts: How many times app was started on current bundle version
    - Reviewed: Storing whether user already reviewed current bundle version
    - TrackedVersion: Currently tracked bundle version of the app
 */
private struct UserDefaultsKey {
    static let AppStarts = "pushReview_AppStarts"
    static let Reviewed = "pushReview_Reviewed"
    static let TrackedVersion = "pushReview_TrackedVersion"
}

/**
 ## PushReview  👻
 To use `PushReview` in your app, simply call `PushReview.configureWithAppId(appId: "123456789", appDelegate: self)` in the beginning of your delegate's `application:didFinishLaunchingWithOptions:` method. Make sure to also call `PushReview.registerNotificationSettings()` somewhere in your app, otherwise PushReview can't display any notifications. Good place to call it is after asking the user for push notifications yourself.
 
 When you know you have a happy user, just call `PushReview.scheduleReviewNotification()` and user will get a notification to review the app a while after he stops using it. You can also set the minimum number of app starts before a notification will be shown by setting `usesBeforePresenting` to a non-nil value.

 Every exposed function of PushReview is properly documented so option-click away and read those sweet docs! 🚀
 
 #### How to trigger a review notification from a push notification
 
 To trigger a PushReview notification with a push, include `pushReview_Category` as its category. Example of a push notification's payload:
 ```
 {
    "aps": {
        "alert": "Hey there! Would you be so cool as to give us a thumbs up on the App Store? 👻",
        "sound": "default",
        "category": "pushReview_Category"
    }
 }
 
 ```
 */
public class PushReview: NSObject {
    /// Apple app id used for opening App Store
    private static var appId: String?
    
    /// Internally used singleton for notifications observation
    private static let sharedInstance = PushReview()
    
    /// When set to `true`, push review notification was already handled in `didFinishLaunchingWithOptions:` and should not be handled later on
    private static var handledReviewPushNotification = false
    
    /// When set to `true`, notification's default action should be performed
    private static var shouldPerformDefaultOption = true
    
    /// When set to `true`, notification will be scheduled when app enters background after `timeBeforePresentingWhenAppEntersBackground`
    private static var shouldScheduleNotificationWhenAppInBackground = false
    
    /// Application name, used for alert title; defaults to application's display name used on device's home screen below app icon
    public static var appName = NSBundle.mainBundle().infoDictionary?["CFBundleDisplayName"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String
    
    /// When set to `false` and an alert is to be presented while the app is active, it waits until the app becomes inactive and presents the alert after delay specified with `timeBeforePresentingWhenAppEntersBackground`; defaults to `false`
    public static var shouldShowWhenAppIsActive = false
    
    /// Delay in seconds until the next time notification is presented; defaults to 24h
    public static var timeBeforeReminding: NSTimeInterval = 60*60*24
    
    /// When `shouldShowWhenAppIsActive == false` and an alert is to be presented, this is the time in seconds the app will wait after going to the background to present the alert; defaults to 5 min
    public static var timeBeforePresentingWhenAppEntersBackground: NSTimeInterval = 60*5
    
    /// When set, it will present a notification after the app has been opened a sufficient amount of times based on `application:didFinishLaunchingWithOptions:`
    public static var usesBeforePresenting: Int?
    
    /// Notification's body text - don't be scared to throw some emojis in there, go crazy!
    public static var bodyText = "Hey there! Would you be so cool as to give us a thumbs up on the App Store? 👻"
    
    /// Title of `Review` call to action button, used in in-app alert popup and as action title on lock screen
    public static var reviewText = "Review"
    
    /// Title of `Later` button, used in in-app alert popup and as action title on lock screen
    public static var laterText = "Later"
    
    /// Title of `Cancel` button presented in the in-app alert popup
    public static var cancelText = "Cancel"
    
    /// Returns `true` if user acted positively to a review prompt notification
    public static var reviewedThisVersion: Bool {
        get { return NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultsKey.Reviewed) }
        set { NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: UserDefaultsKey.Reviewed) }
    }
    
    /**
     ## PushReview  👻
     
     This function configures `PushReview` for your app and is essentially all you need to do to make this work. It should be called somewhere in your `application:didFinishLaunchingWithOptions:`'s implementation. `appDelegate` parameter is used to swizzle `UIApplicationDelegate` methods pertaining notification handling.
     
     To schedule a notification prompting the user to review the app simply call `PushReview.scheduleReviewNotification()` when you know you have a happy user, e.g. he just won something in your game or did a conversion event in your app. User will then get a notification to review the app a while after he stops using it.
     
     Example implementation:
     
     ```
     func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        PushReview.configureWithAppId("123456789", appDelegate: self)
        return true
     }
     ```
     
     - Important: Make sure to call `PushReview.registerNotificationSettings()` somewhere in your app, otherwise PushReview can't display any notifications. Good place to call it is after asking the user for push notifications yourself.
     
     - parameter appId: Your app's Apple Id string used to display proper App Store listing.
     - parameter appDelegate: Pass along the `UIApplicationDelegate` and everything gets taken care by PushReview.
     */
    public static func configureWithAppId(appId: String, appDelegate: UIApplicationDelegate) {
        self.appId = appId
        
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            NSNotificationCenter.defaultCenter().addObserver(sharedInstance, selector: "didEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(sharedInstance, selector: "willEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(sharedInstance, selector: "didFinishLaunching:", name: UIApplicationDidFinishLaunchingNotification, object: nil)
            swizzle(appDelegate)
        }
    }
}

// MARK: - Publicy exposed helper functions

extension PushReview {
    /**
     Opens up App Store for user to review the app. Variable `appId` is used to open up the correct app detail page.
     - parameter appId: When this parameter is present, it overrides `PushReview.appId` variable
     */
    public static func reviewApp(appId: String? = nil) {
        handledReviewPushNotification = true
        reviewedThisVersion = true
        dispatch_async(dispatch_get_main_queue()) {
            let reviewURLTemplate: String
            if #available(iOS 8.0, *) {
                reviewURLTemplate = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"
            } else {
                reviewURLTemplate = "itms-apps://itunes.apple.com/app/id%@"
            }
            
            let appIdToUse = appId ?? self.appId
            if let appId = appIdToUse, reviewURL = NSURL(string: String(format:reviewURLTemplate, appId)) where UIApplication.sharedApplication().canOpenURL(reviewURL) {
                UIApplication.sharedApplication().openURL(reviewURL)
            }
        }
    }
    
    /**
     Presents an alert view on current root view controller asking user to review the app. Options are to review, remind later or cancel.
     */
    public static func presentReviewAlert() {
        guard shouldShowWhenAppIsActive else {
            // Schedule a notification right away if for some reason `applicationDidEnterBackground:` does not get called
            scheduleReviewNotification(delay: timeBeforePresentingWhenAppEntersBackground)
            shouldScheduleNotificationWhenAppInBackground = true
            return
        }
        
        if let topViewController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            if #available(iOS 8.0, *) {
                let alertController = UIAlertController(title: appName, message: bodyText, preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: cancelText, style: .Cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: reviewText, style: .Default) { _ in
                    reviewApp()
                })
                alertController.addAction(UIAlertAction(title: laterText, style: .Default) { _ in
                    scheduleReviewNotification()
                })
                topViewController.presentViewController(alertController, animated: true, completion: nil)
            } else  if let appName = appName {
                UIAlertView(title: appName, message: bodyText, delegate: sharedInstance, cancelButtonTitle: cancelText, otherButtonTitles: reviewText, laterText).show()
            }
        }
    }
    
    /**
     Schedules a local notification after specified delay. Delay defaults to `PushReview.timeBeforeReminding` but can be overriden by giving a `delay` parameter.
     - parameter delay: When this parameter is present, it overrides `PushReview.timeBeforeReminding` variable
     - parameter scheduleEvenIfAlreadyReviewed: By default, notification is not scheduled if user has already reviewed this version. This can be overriden (e.g. for testing) by setting this parameter to `true`
     */
    public static func scheduleReviewNotification(delay delay: NSTimeInterval? = nil, scheduleEvenIfAlreadyReviewed forceSchedule: Bool = false) {
        guard reviewedThisVersion == false || forceSchedule else { return }
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = NSDate(timeIntervalSinceNow: timeBeforePresentingWhenAppEntersBackground)
        localNotification.alertBody = bodyText
        localNotification.alertAction = reviewText
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.userInfo = [Notification.Category: Notification.ReviewCategory]
        
        if let delay = delay {
            localNotification.fireDate = NSDate(timeIntervalSinceNow: delay)
        }
        
        if #available(iOS 8.0, *) {
            localNotification.category = Notification.ReviewCategory
        }
        
        UIApplication.sharedApplication().scheduledLocalNotifications?.forEach({ notification in
            if notification.userInfo?[Notification.Category] as? String == Notification.ReviewCategory {
                UIApplication.sharedApplication().cancelLocalNotification(notification)
            }
        })
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    /**
     Registers notification settings with category for reviewing action. Does not change any of currently set notification types or categories. If user has not previously granted permission for notifications, this presents an alert popup for the user to give permission for displaying notifications.
     - Important: It is recommended to always call `PushReview.registerNotificationSettings()` after registering your own push notification settings as to not override any settings that `PushReview` uses. This function has to be called at least once to be able to display review notifications.
     */
    public static func registerNotificationSettings() {
        if #available(iOS 8.0, *) {
            let reviewAction = UIMutableUserNotificationAction()
            reviewAction.identifier = Notification.Review
            reviewAction.title = reviewText
            reviewAction.activationMode = .Foreground
            reviewAction.destructive = false
            reviewAction.authenticationRequired = true
            
            let laterAction = UIMutableUserNotificationAction()
            laterAction.identifier = Notification.Later
            laterAction.title = laterText
            laterAction.activationMode = .Background
            laterAction.destructive = false
            laterAction.authenticationRequired = false
            
            let reviewCategory = UIMutableUserNotificationCategory()
            reviewCategory.identifier = Notification.ReviewCategory
            reviewCategory.setActions([reviewAction, laterAction], forContext: .Default)
            
            var types = UIApplication.sharedApplication().currentUserNotificationSettings()?.types ?? []
            [UIUserNotificationType.Alert, UIUserNotificationType.Sound].forEach({ types.insert($0) })
            var categories = UIApplication.sharedApplication().currentUserNotificationSettings()?.categories ?? []
            categories.insert(reviewCategory)
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: types, categories: categories))
        }
    }
}

// MARK: - Private implementation

private let delay = { (delay: Double, closure: () -> Void) in
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
}

extension PushReview: UIAlertViewDelegate {
    /**
     Handle UIAlertView delegate functions for devices on < iOS 8.
     */
    @objc public func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            PushReview.presentReviewAlert()
        } else if buttonIndex == 2 {
            PushReview.scheduleReviewNotification(delay: PushReview.timeBeforeReminding)
        }
    }
    
    /**
     Called when application finishes launching.
     */
    @objc private func didFinishLaunching(notification: NSNotification) {
        // Handle local review notification
        if let localNotification = notification.userInfo?[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
            if let category = localNotification.userInfo?[Notification.Category] as? String where category == Notification.ReviewCategory {
                PushReview.reviewApp()
            }
        }
            
        // Handle push review notification
        else if let pushNotification = notification.userInfo?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject: AnyObject] {
            if let category = pushNotification[Notification.Category] as? String where category == Notification.ReviewCategory {
                PushReview.reviewApp()
            }
        }
        
        // Wait for the application to properly start and if it is active, do some internal magic
        delay(1) {
            if UIApplication.sharedApplication().applicationState == .Active {
                PushReview.shouldPerformDefaultOption = false
                
                // Check current app version and update counters if needeed
                if let currentVersion = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as? String {
                    if let trackedVersion = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.TrackedVersion) as? String where trackedVersion != currentVersion {
                        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: UserDefaultsKey.AppStarts)
                        PushReview.reviewedThisVersion = false
                    }
                    NSUserDefaults.standardUserDefaults().setObject(currentVersion, forKey: UserDefaultsKey.TrackedVersion)
                }
                
                // Increase app start counter and optionally schedule review notification right away if condition is met
                let appStarts = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultsKey.AppStarts) + 1
                NSUserDefaults.standardUserDefaults().setInteger(appStarts, forKey: UserDefaultsKey.AppStarts)
                if appStarts == PushReview.usesBeforePresenting {
                    PushReview.scheduleReviewNotification(delay: 0)
                }
            }
        }
    }
    
    /**
     Called whenever application enters background.
     */
    @objc private func didEnterBackground(notification: NSNotification) {
        PushReview.shouldPerformDefaultOption = true
        
        if PushReview.shouldScheduleNotificationWhenAppInBackground {
            PushReview.scheduleReviewNotification()
            PushReview.shouldScheduleNotificationWhenAppInBackground = false
        }
    }
    
    /**
     Called whenever application will enter foreground.
     */
    @objc private func willEnterForeground(notification: NSNotification) {
        // Delay call for one second to make sure the app was not opened through push action
        delay(1) {
            PushReview.shouldPerformDefaultOption = false
        }
    }
    
    /**
     Swizzles appropriate application delegate methods to handle notif5ications internally.
     - parameter delegate: `UIApplicationDelegate` instance for which methods should be swizzled.
     */
    private static func swizzle(delegate: UIApplicationDelegate) {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // Swizzles original selector with given swizzled selector
        let swizzle = { (originalSelector: Selector, swizzledSelector: Selector) in
            let originalMethod = class_getInstanceMethod(delegate.dynamicType, originalSelector)
            let swizzledMethod = class_getInstanceMethod(delegate.dynamicType, swizzledSelector)
            
            let didAddMethod = class_addMethod(delegate.dynamicType, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            if didAddMethod {
                class_replaceMethod(delegate.dynamicType, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
        
        dispatch_once(&Static.token) {
            swizzle(Selector("application:didReceiveLocalNotification:"), Selector("pushReview_application:didReceiveLocalNotification:"))
            swizzle(Selector("application:didReceiveRemoteNotification:fetchCompletionHandler:"), Selector("pushReview_application:didReceiveRemoteNotification:fetchCompletionHandler:"))
            swizzle(Selector("application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:"), Selector("pushReview_application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:"))
            swizzle(Selector("application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:"), Selector("pushReview_application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:"))
        }
    }
    
    /**
     Called when a notification is received, either a local one or a remote notification.
     - parameter userInfo: Dictionary containing `userInfo` of received notification. In case of local notification, you can extract this as `notification.userInfo`.
     */
    private static func didReceiveNotification(userInfo: [NSObject : AnyObject]?) {
        if let category = userInfo?[Notification.Category] as? String where category == Notification.ReviewCategory && !PushReview.handledReviewPushNotification {
            if PushReview.shouldPerformDefaultOption {
                PushReview.reviewApp()
            } else {
                PushReview.presentReviewAlert()
            }
        }
    }
    
    /**
     Called when a notification action is triggered, either from a local notification or a remote notification.
     - parameter identifier: Action identifier retrieved as delegate function parameter.
     - parameter forNotification: Notification user info retreived as delegate function parameter.
     */
    private static func handleActionWithIdentifier(identifier: String?, forNotification userInfo: [NSObject : AnyObject]?) {
        if let category = userInfo?[Notification.Category] as? String where category == Notification.ReviewCategory {
            switch identifier {
            case .Some(Notification.Review):
                PushReview.reviewApp()
            case .Some(Notification.Later):
                PushReview.scheduleReviewNotification(delay: PushReview.timeBeforeReminding)
            default:
                break
            }
        }
    }
}

// MARK: - Swizzled methods

extension UIResponder {
    @objc private func pushReview_application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if respondsToSelector(Selector("pushReview_application:didReceiveLocalNotification:")) {
            pushReview_application(application, didReceiveLocalNotification: notification)
        }
        
        PushReview.didReceiveNotification(notification.userInfo)
    }
    
    @objc private func pushReview_application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        var shouldCallCompletionHandler = true
        if respondsToSelector(Selector("pushReview_application:didReceiveRemoteNotification:fetchCompletionHandler:")) {
            pushReview_application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
            shouldCallCompletionHandler = false
        }
        if respondsToSelector(Selector("application:didReceiveRemoteNotification:")) {
            (self as? UIApplicationDelegate)?.application?(application, didReceiveRemoteNotification: userInfo)
        }
        
        PushReview.didReceiveNotification(userInfo["aps"] as? [NSObject : AnyObject])
        
        if shouldCallCompletionHandler {
            completionHandler(.NoData)
        }
    }
    
    @objc private func pushReview_application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        var shouldCallCompletionHandler = true
        if respondsToSelector(Selector("pushReview_application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:")) {
            pushReview_application(application, handleActionWithIdentifier: identifier, forLocalNotification: notification, withResponseInfo: responseInfo, completionHandler: completionHandler)
            shouldCallCompletionHandler = false
        }
        if respondsToSelector(Selector("application:handleActionWithIdentifier:forLocalNotification:completionHandler:")) {
            if #available(iOS 8.0, *) {
                (self as? UIApplicationDelegate)?.application?(application, handleActionWithIdentifier: identifier, forLocalNotification: notification, completionHandler: completionHandler)
                shouldCallCompletionHandler = false
            }
        }
        
        PushReview.handleActionWithIdentifier(identifier, forNotification: notification.userInfo)
        
        if shouldCallCompletionHandler {
            completionHandler()
        }
    }
    
    @objc private func pushReview_application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        var shouldCallCompletionHandler = true
        if respondsToSelector(Selector("pushReview_application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:")) {
            pushReview_application(application, handleActionWithIdentifier: identifier, forRemoteNotification: userInfo, withResponseInfo: responseInfo, completionHandler: completionHandler)
            shouldCallCompletionHandler = false
        }
        if respondsToSelector(Selector("application:handleActionWithIdentifier:forRemoteNotification:completionHandler:")) {
            if #available(iOS 8.0, *) {
                (self as? UIApplicationDelegate)?.application?(application, handleActionWithIdentifier: identifier, forRemoteNotification: userInfo, completionHandler: completionHandler)
                shouldCallCompletionHandler = false
            }
        }
        
        PushReview.handleActionWithIdentifier(identifier, forNotification: userInfo["aps"] as? [NSObject : AnyObject])
        
        if shouldCallCompletionHandler {
            completionHandler()
        }
    }
}
