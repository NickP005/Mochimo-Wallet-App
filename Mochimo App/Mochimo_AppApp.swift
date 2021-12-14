//
//  Mochimo_AppApp.swift
//  Mochimo App
//
//  Created by User on 01/09/21.
//

import SwiftUI
import IQKeyboardManagerSwift

@main
struct Mochimo_AppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.previousNextDisplayMode = .alwaysShow
        
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
               didFinishLaunchingWithOptions launchOptions:
                [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       // Override point for customization after application launch.you’re
        print("registering for notification")
        
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    func application(_ application: UIApplication,
                didRegisterForRemoteNotificationsWithDeviceToken
                    deviceToken: Data) {
        print("retrieved the device token!!", deviceToken.toHexString())
        WalletListManager.singleton.apn_token = deviceToken.toHexString()
       //self.sendDeviceTokenToServer(data: deviceToken)
    }

    func application(_ application: UIApplication,
                didFailToRegisterForRemoteNotificationsWithError
                    error: Error) {
        print("failed to regiser", error)
       // Try again later.
    }
}
