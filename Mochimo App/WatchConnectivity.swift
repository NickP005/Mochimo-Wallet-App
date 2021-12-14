//
//  WatchConnectivity.swift
//  Mochimo App
//
//  Created by User on 05/09/21.
//

import Foundation
import WatchConnectivity

class ViewModelPhone : NSObject,  WCSessionDelegate{
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("sessione inizia")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessione inattiva")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessione deattivata")
    }
    
    
}
