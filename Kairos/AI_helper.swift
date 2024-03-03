//
//  AI_helper.swift
//  Kairos
//
//  Created by Nikhil Tien on 2/29/24.
//

import Foundation

func sendEventToServer(title: String, startDate: Date, endDate: Date, completion: @escaping (Bool, ServerResponse?) -> Void) {
    guard let url = URL(string: "https://kairos-tech.xyz/api/assistant/") else {
        print("Invalid URL")
        completion(false, nil)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime]
    
    let parameters: [String: Any] = [
        "title": title,
        "startDate": dateFormatter.string(from: startDate),
        "endDate": dateFormatter.string(from: endDate)
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        completion(false, nil)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error in sending event: \(error?.localizedDescription ?? "Unknown error")")
            completion(false, nil)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Server error with response code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            completion(false, nil)
            return
        }
        
        do {
            let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
            NotificationCenter.default.post(name: NSNotification.Name("ReceivedDataFromServer"), object: nil, userInfo: ["response": serverResponse])
            completion(true, serverResponse)
        } catch {
            print("Error decoding server response: \(error)")
            completion(false, nil)
        }
    }
    
    task.resume()
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(escapedKey)=\(escapedValue)"
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

struct ServerResponse: Codable {
    var response: String
}
