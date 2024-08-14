import SwiftUI
import WebKit

public enum AIType: String {
    case intent = "intent"
    case churn = "churn"
    // case delete = "delete"
    // case subscriber = "subscriber"
    // case presubscription = "presubscription"
    // case precancel = "precancel"
}

public struct ResubscribeOptions {
    let slug: String
    let apiKey: String
    let aiType: AIType
    let userId: String
    let userEmail: String?
    let title: String?
    let description: String?
    let primaryButtonText: String?
    let cancelButtonText: String?
    let onClose: ((String) -> Void)?
    let colors: ResubscribeColors?
}

public struct ResubscribeColors {
    let primary: Color
    let text: Color
    let background: Color
}

class ResubscribeStore: ObservableObject {
    @Published var state: String = "closed"
    @Published var options: ResubscribeOptions?
    
    func openConsent(_ options: ResubscribeOptions) {
        self.options = options
        self.state = "confirming"
    }
    
    func close() {
        self.state = "closed"
        self.options = nil
    }
}

struct ResubscribeView: View {
    @ObservedObject var store: ResubscribeStore
    
    var body: some View {
        Group {
            if store.state == "confirming" {
                consentView
            } else if store.state == "open" {
                chatView
            }
        }
    }
    
    var consentView: some View {
        VStack {
            Text(store.options?.title ?? Utils.getTitle(for: store.options!.aiType))
                .font(.headline)
            Text(store.options?.description ?? Utils.getDescription(for: store.options!.aiType))
                .font(.subheadline)
            HStack {
                Button(store.options?.cancelButtonText ?? "Not right now") {
                    store.close()
                    store.options?.onClose?("cancel-consent")
                }
                Button(store.options?.primaryButtonText ?? "Let's chat!") {
                    store.state = "open"
                }
            }
        }
        .padding()
        .background(store.options?.colors?.background ?? Color.white)
        .foregroundColor(store.options?.colors?.text ?? Color.black)
    }
    
    var chatView: some View {
        WebView(url: Utils.buildUrl(options: store.options!))
            .edgesIgnoringSafeArea(.all)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

class ResubscribeCls {
    private let store = ResubscribeStore()
    
    public init() {}
    
    public func openWithConsent(_ options: ResubscribeOptions) {
        Utils.registerConsent(options: options)
        store.openConsent(options)
    }
    
    public var view: some View {
        ResubscribeView(store: store)
    }
}

public let Resubscribe = ResubscribeCls()
