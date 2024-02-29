//
//  AI_helper.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/29/24.
//

import Foundation

func sendEventToServer(title: String, startDate: Date, endDate: Date, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "http://161.35.251.225/") else {
        print("Invalid URL")
        completion(false)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let dateFormatter = ISO8601DateFormatter()
    let parameters: [String: String] = [
        "title": title,
        "startDate": dateFormatter.string(from: startDate),
        "endDate": dateFormatter.string(from: endDate)
    ]

    request.httpBody = parameters.percentEncoded()

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // Log the error if any occurred
        if let error = error {
            print("Error in sending event: \(error.localizedDescription)")
            completion(false)
            return
        }

        // Log the HTTP response and status code
        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
        }

        // Decode the response data to a String and log it
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        } else {
            print("No response data to decode.")
        }

        completion(true)
    }

    task.resume()
}


extension Dictionary {
    func percentEncoded() -> Data? {
        let encodedPairs = map { key, value -> String in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            return "\(escapedKey)=\(escapedValue)"
        }
        return encodedPairs.joined(separator: "&").data(using: .utf8)
    }
}
