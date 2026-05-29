import SwiftUI

struct WalletButtonView: View {
    let icon: String
    let title: String
    let accent: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: .margin8) {
            IconButton(icon: icon, style: accent ? .primary : .secondary, action: action)
            Text(title).textCaption()
        }
    }
}
