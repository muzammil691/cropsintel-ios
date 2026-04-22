import SwiftUI
import WebKit

/// WKWebView wrapper that loads CropsIntel V2 — the autonomous trading intelligence platform.
/// V2 is powered by Zyra AI with learning memory, real ABC data, and multi-channel intelligence.
/// Any update pushed to the V2 repo is instantly live via GitHub Pages auto-deploy.
struct CropsIntelWebView: UIViewRepresentable {

    // V2 platform — cropsintel.com (primary domain, GitHub Pages)
    private let url = URL(string: "https://cropsintel.com")!

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Enable JavaScript for Zyra AI widget, Recharts, and interactive features
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false
        webView.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)
        webView.isOpaque = false

        // V2 user agent — site detects native shell for optimized mobile experience
        webView.customUserAgent = "CropsIntel-iOS/2.0 (V2-Autonomous)"

        // Clear all cached data on launch to avoid stale content after domain changes
        let dataStore = WKWebsiteDataStore.default()
        dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) { }
        // Force fresh load — never use cached 404s or redirects
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {

        // Allow all navigation within cropsintel.com; open external links in Safari
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let host = navigationAction.request.url?.host,
               host.contains("cropsintel") || host.contains("supabase") || host.contains("anthropic") || host.contains("elevenlabs") {
                decisionHandler(.allow)
            } else if navigationAction.navigationType == .linkActivated,
                      let url = navigationAction.request.url {
                // External links open in Safari
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        // Handle JavaScript alerts from Zyra widget
        func webView(_ webView: WKWebView,
                     runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping () -> Void) {
            completionHandler()
        }

        // Show a branded offline screen if load fails
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let html = """
            <html>
            <head><meta name='viewport' content='width=device-width, initial-scale=1'></head>
            <body style='background:#0a0a0f;color:#ccc;font-family:system-ui;text-align:center;padding-top:30%'>
            <div style='font-size:48px;margin-bottom:16px'>🌾</div>
            <h2 style='color:#d4b16a;margin-bottom:8px'>CropsIntel V2</h2>
            <p style='color:#888;margin-bottom:24px'>Unable to connect. Please check your internet and try again.</p>
            <button onclick='location.reload()' style='padding:14px 32px;border-radius:10px;border:none;background:linear-gradient(135deg,#d4b16a,#c4a050);color:#000;font-size:16px;font-weight:600;cursor:pointer'>Reconnect</button>
            <p style='color:#555;font-size:12px;margin-top:40px'>Powered by Zyra AI</p>
            </body></html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
}
