import SwiftUI

struct WalletButtonView: View {
    let icon: String
    let title: String
    let accent: Bool
    var identifier: String?
    let action: () -> Void

    var body: some View {
        let button = IconButton(icon: icon, style: accent ? .primary : .secondary, action: action)
            .accessibilityLabel(title)

        if let identifier {
            button.accessibilityIdentifier(identifier)
        } else {
            button
        }
    }
}
