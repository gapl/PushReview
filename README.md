<h1 align="center">PushReview 📲</h1>

<p align="center">
	<a href="https://developer.apple.com/swift"><img alt="Swift 2.0" src="https://img.shields.io/badge/Swift-2.0-orange.svg?style=flat"/></a>
	<a href="http://cocoapods.org/pods/PushReview"><img alt="Version" src="https://img.shields.io/cocoapods/v/PushReview.svg?style=flat"/></a>
	<a href="http://cocoapods.org/pods/PushReview"><img alt="Platform" src="https://img.shields.io/cocoapods/p/PushReview.svg?style=flat"/></a>
</p>

PushReview is a library aimed at getting your app the reviews it deserves 🙌. Most common way of asking the user to leave a review on the App Store is very intrusive as it involves showing an alert view while the user is using the app and essentially worsening her user experience. It makes way more sense to ask the user to review your app while she is not using it, e.g. waiting for her train to arrive and she has 5 minutes to burn before it arrives 🕗🚅.


![review](https://cloud.githubusercontent.com/assets/16098948/13726376/fcd46f02-e8c4-11e5-98d7-febebba2c749.gif) | ![later](https://cloud.githubusercontent.com/assets/16098948/13726375/fc91a10e-e8c4-11e5-85cf-159d532368b9.gif) 
:---:|:---:
**Selecting Review** | **Selecting Later** 
Opens up the app and goes straight to the App Store<br />to review. Same thing happens when user swipes or taps the notification. | Removes the notification and schedules a new prompt for the next day. 

## Usage

In order to start using PushReview, there are two calls you need to make:

1. Call `PushReview.configureWithAppId(appId: "app_id", appDelegate: self)` in your delegate's `application:didFinishLaunchingWithOptions:` method with the app id provided by Apple.
2. As PushReview needs to display notifications, you need to call `PushReview.registerNotificationSettings()` somewhere in your app. A good place to call it is right after asking the user for push notifications yourself.

#### Example

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    // Your app's code...

    PushReview.configureWithAppId("0123456789", appDelegate: self)
    PushReview.registerNotificationSettings()
    PushReview.usesBeforePresenting = 10

    return true
}
```

#### Asking for review

There are two ways to prompt user for a review:

1. Preffered method is by knowing who your happy users are. When you have identified a user as a happy user, simply do the following based on whether you have this information on the client side or server side:

	1. **Client side:** Simply call `PushReview.scheduleReviewNotification()` and everything will be handled by PushReview. There will be a notification displayed a while after the user stops using the app.
	
	2. **Server side:** Send a push notification with `pushReview_Category` as its category. Example payload:
	
	```json
	{
		"aps": {
			"alert": "Hey there! Would you be so cool as to give us a thumbs up on the App Store? 👻",
			"sound": "default",
			"category": "pushReview_Category"
		}
	}
	```
	
2. If you have no way of knowing who your happy users are, you can always fall back to number of app starts. Because hey, if a user opens your app 20 times, she must be happy 😎. In this case, just set `usesBeforePresenting` to a number that you particularly like, e.g. `PushReview.usesBeforePresenting = 20`.

#### Customization

Even though PushReview is made as such that it just works out of the box, there are a number of ways to customize it to work just the way you want it to work.

- **Localization:** To localize review notifications you can edit `bodyText` and several other variables.
- **Number of uses:** To show a notification after a certain number of app uses, simply set `usesBeforePresenting` to something other than `nil`.
- **In-app alerts:** Even though PushReview is all for staying in the background and just presenting notifications on the lock screen, you can actually make it work also while the app is in foreground. To do so, simply set `shouldShowWhenAppIsActive` to `true` and it will display a neat little alert view when needed.
- **Delays:** All delay times are configurable, such as what should be the time until the user is asked again (`timeBeforeReminding`) and also what should be the delay until the notification is presented after the app goes to the background (`timeBeforePresentingWhenAppEntersBackground`).

#### Playing around

To see PushReview in action, there are of course several ways of playing around with it.

- **Test notification:** To quickly see PushReview in action, call `PushReview.scheduleReviewNotification(delay: 10)` and lock your device. You should see a neat little notification poping up after 10 seconds.
- **Old fashioned alert:** To present an old fashioned in-app alert, simply set `PushReview.shouldShowWhenAppIsActive = true` and call `PushReview.presentReviewAlert()`. This will bring up the old fashioned alert view that we all love to hate.
- **Review app:** Who doesn't have a review button in their app somewhere, right? Leave the implementation logic of that to PushReview and just call `PushReview.reviewApp()`. Simple.

## Requirements

- iOS 7.0+
- Swift 2.0

## Installation

Recommend way to install PushReview is using [CocoaPods](http://cocoapods.org).

Just put this in your `Podfile`:

```ruby
use_frameworks!

pod 'PushReview'
```

When using iOS 7, copy and paste the `PushReview.swift` file in your Xcode project.

### License
PushReview is released under the MIT license. See LICENSE for details.
