//
//  NotificationManager.swift
//  Mochimo App
//
//  Created by User on 02/10/21.
//

import Foundation

class NotificationManager {
    func updateTags(deviceToken: String, tags: [String]) {
        
        let url = URL(string: "https://wallet.mochimo.com/notification/ios/update.php")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "aim": "subscribe",
            "deviceToken": deviceToken,
            "tags" : tags
        ]
        request.httpBody = parameters.percentEncoded()

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
            }

            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }

            let responseString = String(data: data, encoding: .utf8)
            print("responseString = ", responseString!)
        }

        task.resume()
    }
}
