import SwiftUI
import WebKit

struct UserAgreementView: View {
    let onFailure: (TravelFailure) -> Void
    @State private var isLoading = true
    @State private var didFail = false
    @State private var reloadID = 0

    var body: some View {
        VStack(spacing: 0) {
            TravelNavigationHeader(title: "Пользовательское соглашение")
            ZStack {
                AgreementWebView(isLoading: $isLoading, reloadID: reloadID) { failure in
                    didFail = true
                    onFailure(failure)
                }
                if isLoading { ProgressView().controlSize(.large) }
                if didFail {
                    Button {
                        didFail = false
                        isLoading = true
                        reloadID += 1
                    } label: {
                        PrimaryActionLabel(title: "Повторить")
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TravelStyle.background)
                }
            }
        }
        .background(TravelStyle.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct AgreementWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    let reloadID: Int
    let onFailure: (TravelFailure) -> Void
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        context.coordinator.parent = self
        view.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        guard context.coordinator.reloadID != reloadID,
              let url = URL(string: "https://yandex.ru/legal/practicum_offer/") else { return }
        context.coordinator.reloadID = reloadID
        view.load(URLRequest(url: url))
    }

    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.navigationDelegate = nil
        view.stopLoading()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: AgreementWebView
        var reloadID = -1

        init(parent: AgreementWebView) { self.parent = parent }

        func shouldAllow(_ response: URLResponse, isMainFrame: Bool) -> Bool {
            guard isMainFrame, let response = response as? HTTPURLResponse,
                  response.statusCode >= 400 else { return true }
            parent.isLoading = false
            parent.onFailure(.server)
            return false
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(shouldAllow(navigationResponse.response, isMainFrame: navigationResponse.isForMainFrame) ? .allow : .cancel)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.isLoading = false
            parent.onFailure(.server)
        }

        private func handle(_ error: Error) {
            let error = error as NSError
            guard error.domain != NSURLErrorDomain || error.code != NSURLErrorCancelled else { return }
            parent.isLoading = false
            let offlineCodes = [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorDataNotAllowed]
            parent.onFailure(error.domain == NSURLErrorDomain && offlineCodes.contains(error.code) ? .offline : .server)
        }
    }
}
