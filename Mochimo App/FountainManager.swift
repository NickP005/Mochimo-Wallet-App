//
//  FountainManager.swift
//  Mochimo App
//
//  Created by User on 09/09/21.
//

import Foundation

class FountainManager: NSObject, URLSessionDelegate {
    func fund_address(_ base_url: String, bytes: [UInt8], completion: @escaping (Bool, String) -> Void) {
        let url : String = base_url + "/" + bytes.toHexString()
        var request = URLRequest(url: URL(string: url)!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                //print("data from fountain", data)
                if let webResponse = String(data: data, encoding: .utf8) {
                    print("delayes response: " + webResponse)
                    if let httpResponse = response as? HTTPURLResponse {
                        if(httpResponse.statusCode == 200) {
                            completion(true, webResponse)
                            return
                        } else {
                            completion(false, webResponse)
                            return
                        }
                    } else {
                        completion(true, webResponse)
                    }
                    //completion(webResponse)
                    //loadingAnimationClass().stopLoadingAnimationLogin()
                } else {
                    completion(false, "")
                }
                /*
                if let books = try? JSONDecoder().decode(from: data) {
                    print(books)
                } else {
                    print("Invalid Response")
                }*/
            } else if let error = error {
                print("HTTP Request Failed \(error)")
                completion(false, "")
            }
        }
        task.resume()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let trust = challenge.protectionSpace.serverTrust {
                    completionHandler(.useCredential, URLCredential(trust: trust))
                }
            }
        }
}
