import SwiftUI

struct WalletButtonView: View {
    let icon: String
    let title: String
    let accent: Bool
    var identifier: String? = nil
    let action: () -> Void

    var body: some View {
        VStack(spacing: .margin8) {
            let button = IconButton(icon: icon, style: accent ? .primary : .secondary, action: action)

            if let identifier {
                button.accessibilityIdentifier(identifier)
            } else {
                button
            }

            Text(title).textCaption()
        }
    }
}
