import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Ensure transparency
        config.websiteDataStore = .nonPersistent()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        // Load the GIF
        do {
            let data = try Data(contentsOf: url)
            webView.load(data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url.deletingLastPathComponent())
        } catch {
            print("Error loading GIF data: \(error)")
        }
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Reload if URL changes significantly, but typically this view is recreated
    }
}
