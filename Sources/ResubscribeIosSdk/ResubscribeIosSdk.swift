import SwiftUI
import WebKit

public enum AIType: String {
    case intent = "intent"
    case churn = "churn"
}

public struct ResubscribeOptions {
    public init(slug: String, apiKey: String, aiType: AIType, userId: String, userEmail: String? = nil, title: String? = nil, description: String? = nil, primaryButtonText: String? = nil, cancelButtonText: String? = nil, colors: ResubscribeColors? = nil, onClose: ((String) -> Void)? = nil) {
        self.slug = slug
        self.apiKey = apiKey
        self.aiType = aiType
        self.userId = userId
        self.userEmail = userEmail
        self.title = title
        self.description = description
        self.primaryButtonText = primaryButtonText
        self.cancelButtonText = cancelButtonText
        self.colors = colors
        self.onClose = onClose
    }
    
    let slug: String
    let apiKey: String
    let aiType: AIType
    let userId: String
    let userEmail: String?
    let title: String?
    let description: String?
    let primaryButtonText: String?
    let cancelButtonText: String?
    let colors: ResubscribeColors?
    let onClose: ((String) -> Void)?
}

public struct ResubscribeColors {
    public init(primary: Color, text: Color, background: Color) {
        self.primary = primary
        self.text = text
        self.background = background
    }
    
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
    @State private var showConfirmationDialog = false
    
    private var shouldShow: Binding<Bool> {
        Binding(
            get: { self.store.state == "confirming" || self.store.state == "open" },
            set: { newValue in
                if !newValue {
                    self.store.close()
                }
            }
        )
    }
    
    var body: some View {
        Group {
            VStack {}
                .fullScreenCover(isPresented: shouldShow) {
                    if store.state == "confirming" {
                        consentView
                    } else if store.state == "open" {
                        chatView
                    }
                }
        }
    }
    
    var consentView: some View {
        VStack(spacing: 20) {
            Text(store.options?.title ?? Utils.getTitle(for: store.options!.aiType))
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
            
            Text(store.options?.description ?? Utils.getDescription(for: store.options!.aiType))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(Color.gray)
            
            VStack(spacing: 12) {
                Button(store.options?.primaryButtonText ?? "Let's chat!") {
                    store.state = "open"
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: store.options?.colors?.primary ?? Color.blue))
                
                Button(store.options?.cancelButtonText ?? "Not right now") {
                    store.close()
                    store.options?.onClose?("cancel-consent")
                }
                .buttonStyle(SecondaryButtonStyle(textColor: store.options?.colors?.text ?? Color.black))
            }
        }
        .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        .background(store.options?.colors?.background ?? Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .frame(maxWidth: 400)
        .padding(.horizontal, 20)
    }
    
    struct PrimaryButtonStyle: ButtonStyle {
        let backgroundColor: Color
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
        }
    }
    
    struct SecondaryButtonStyle: ButtonStyle {
        let textColor: Color
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                .foregroundColor(textColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(textColor, lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
        }
    }
    
    var chatView: some View {
        ZStack {
            WebView(url: Utils.buildUrl(options: store.options!))
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showConfirmationDialog = true
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.top, 14)
                    .padding(.trailing, 14)
                }
                Spacer()
            }
        }
        .alert(isPresented: $showConfirmationDialog) {
            Alert(
                title: Text("Close Chat?"),
                message: Text("Are you sure you want to close the chat?"),
                primaryButton: .destructive(Text("Yes")) {
                    store.close()
                    store.options?.onClose?("close")
                },
                secondaryButton: .cancel()
            )
        }
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

public class ResubscribeCls {
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
