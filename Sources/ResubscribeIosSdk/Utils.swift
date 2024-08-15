import Foundation
import SwiftUI
import OSLog

struct Utils {
    static let apiBaseUrl = "https://api.resubscribe.ai"
    static let appBaseUrl = "https://app.resubscribe.ai"
    
    static func getNavigatorLanguage() -> String {
        return Locale.current.languageCode ?? "en"
    }
    
    static func isDarkColor(_ color: Color) -> Bool {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.5
    }
    
    static func getTitle(for aiType: AIType) -> String {
        switch aiType {
        case .intent:
            return "How can we help you today?"
        case .churn:
            return "Before you go, let's chat"
        }
    }
    
    static func getDescription(for aiType: AIType) -> String {
        switch aiType {
        case .intent:
            return "Our AI assistant is here to help with any questions or concerns you may have."
        case .churn:
            return "We'd love to understand your concerns and see if there's anything we can do to keep you as a valued customer."
        }
    }
    
    static func buildUrl(options: ResubscribeOptions) -> URL {
        var components = URLComponents(string: "\(appBaseUrl)/chat/\(options.slug)")!
        var queryItems = [
            URLQueryItem(name: "ait", value: options.aiType.rawValue),
            URLQueryItem(name: "uid", value: options.userId),
            URLQueryItem(name: "iframe", value: "true"),
            URLQueryItem(name: "hideclose", value: "true")
        ]
        if let email = options.userEmail {
            queryItems.append(URLQueryItem(name: "email", value: email))
        }
        components.queryItems = queryItems
        components.fragment = "apiKey=\(options.apiKey)"
        let url = components.url!
        let dl = Logger()
        dl.debug("URL: \(url)")
        return url
    }
    
    static func registerConsent(options: ResubscribeOptions) {
        let url = URL(string: "\(apiBaseUrl)/sessions/consent")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(options.apiKey, forHTTPHeaderField: "X-API-Key")
        
        var queryItems = [
            URLQueryItem(name: "slug", value: options.slug),
            URLQueryItem(name: "uid", value: options.userId),
            URLQueryItem(name: "ait", value: options.aiType.rawValue),
            URLQueryItem(name: "brloc", value: getNavigatorLanguage())
        ]
        if let email = options.userEmail {
            queryItems.append(URLQueryItem(name: "email", value: email))
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        request.url = components.url
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Failed to register consent: \(error)")
            }
        }.resume()
    }
}
