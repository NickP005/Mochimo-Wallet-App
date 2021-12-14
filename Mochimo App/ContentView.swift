//
//  ContentView.swift
//  Mochimo App
//
//  Created by User on 01/09/21.
//

import SwiftUI
import NIO
struct ContentView: View {
    
    //@ObservedObject var socketManager: SocketManagerClass
    @ObservedObject var screenManager: ViewManager = ViewManager.singleton
    
/*    init() {
        socketManager = SocketManagerClass.singleton
    }*/
    var body: some View {
        if(screenManager.screen == "first_loading") {
            LoadingScreen()
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        screenManager.prepareApp() {
                            ViewManager.singleton.screen = "wallet_list"
                        }
                    }
                }
        } else if (screenManager.screen == "wallet_list") {
            WalletListView()
        } else {
            Text("ERROR")
        }
    }
}

class ViewManager: ObservableObject {
    static var singleton: ViewManager = ViewManager()
    @Published var screen = "first_loading"
    @Published var bottomsheet_screen = "null"
    
    //Apple Watch connectivity
    @Published var model = ViewModelPhone()
    
    func prepareApp(completion: @escaping () -> ()) {
        let first_time: Bool = UserDefaults.standard.bool(forKey: "already_opened")
        if(!first_time) {
            print("setting up all the variable for the first time")
            setUpFirstTime()
        }
        WalletListManager.singleton.getWalletsOfflineMode()

        //All the managing stuff is completed and so we can fire the app
        completion()
    }
    func setUpFirstTime() {
        UserDefaults.standard.set(true, forKey: "already_opened")
        UserDefaults.standard.setValue(0, forKey: "iter_wallets")
    }
}
/*
class SocketManagerClass: ObservableObject {
    static var singleton: SocketManagerClass = SocketManagerClass()    
    var client: Node
    var channel: Channel?
    init() {
        //35.207.11.60
        
        client = Node(ip: "35.207.11.60", port: 2095)
        do {
            try client.connect() {channell in
                self.channel = channell
            }
        } catch {
            print(error)
        }
    }
}*/

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

