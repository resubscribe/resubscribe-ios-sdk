import Foundation
import SwiftUI

struct Utils {
    static let baseUrl = "https://api.resubscribe.ai"
    
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
        case .delete:
            return "Before you delete your account"
        case .subscriber:
            return "Welcome back!"
        case .presubscription:
            return "Before you subscribe"
        case .precancel:
            return "Before you cancel"
        }
    }
    
    static func getDescription(for aiType: AIType) -> String {
        switch aiType {
        case .intent:
            return "Our AI assistant is here to help with any questions or concerns you may have."
        case .churn:
            return "We'd love to understand your concerns and see if there's anything we can do to keep you as a valued customer."
        case .delete:
            return "We're sorry to see you go. Can we chat briefly about your decision to delete your account?"
        case .subscriber:
            return "We're glad to have you back. How can we assist you today?"
        case .presubscription:
            return "Before you subscribe, let's make sure all your questions are answered."
        case .precancel:
            return "Before you cancel, we'd like to understand your concerns and see if there's a way we can address them."
        }
    }
    
    static func buildUrl(options: ResubscribeOptions) -> URL {
        var components = URLComponents(string: "\(baseUrl)/chat/\(options.slug)")!
        components.queryItems = [
            URLQueryItem(name: "ait", value: options.aiType.rawValue),
            URLQueryItem(name: "uid", value: options.userId),
            URLQueryItem(name: "email", value: options.userEmail),
            URLQueryItem(name: "iframe", value: "true"),
            URLQueryItem(name: "hideclose", value: "true")
        ]
        let url = components.url!
        return url.appendingFragment("apiKey=\(options.apiKey)")
    }
    
    static func registerConsent(options: ResubscribeOptions) {
        let url = URL(string: "\(baseUrl)/sessions/consent")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(options.apiKey, forHTTPHeaderField: "X-API-Key")
        
        let queryItems = [
            URLQueryItem(name: "slug", value: options.slug),
            URLQueryItem(name: "uid", value: options.userId),
            URLQueryItem(name: "email", value: options.userEmail),
            URLQueryItem(name: "ait", value: options.aiType.rawValue),
            URLQueryItem(name: "brloc", value: getNavigatorLanguage())
        ]
        
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