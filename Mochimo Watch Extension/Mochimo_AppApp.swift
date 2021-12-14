//
//  Mochimo_AppApp.swift
//  Mochimo Watch Extension
//
//  Created by User on 05/09/21.
//

import SwiftUI

@main
struct Mochimo_AppApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
