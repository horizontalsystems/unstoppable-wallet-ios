import SwiftUI

// Grabber, dApp icon, request title, host and an optional explanation; the top of a request sheet
struct WCSendHeaderField: SendFieldContent {
    let iconUrl: String?
    let title: String
    let host: String?
    let description: String?

    @ViewBuilder @MainActor func listRow() -> some View {
        VStack(spacing: 0) {
            WCDAppTitleView(iconUrl: iconUrl, title: title, showGrabber: true)
            if let host {
                BSModule.view(for: .subtitle(text: host))
            }
            if let description {
                BSModule.view(for: .text(text: description))
            }
        }
    }
}
