import SwiftUI
import WebKit

struct CropsIntelWebView: UIViewRepresentable {

    private let url = URL(string: "https://cropsintel.com")!

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false
        webView.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)
        webView.isOpaque = false
        webView.customUserAgent = "CropsIntel-iOS/2.0 (V2)"
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            let html = """
            <html>
            <head><meta name='viewport' content='width=device-width, initial-scale=1'></head>
            <body style='background:#111;color:#ccc;font-family:system-ui;text-align:center;padding-top:40%;margin:0'>
            <h2 style='color:#d4b16a'>No Connection</h2>
            <p>Please check your internet connection and try again.</p>
            <button onclick='location.reload()'
              style='padding:12px 24px;border-radius:8px;border:none;background:#d4b16a;color:#000;font-size:16px;margin-top:12px'>
              Retry
            </button>
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
}
