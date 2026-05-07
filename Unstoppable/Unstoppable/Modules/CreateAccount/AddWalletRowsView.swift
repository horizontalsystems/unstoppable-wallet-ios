import SwiftUI

struct AddWalletRowsView: View {
    let onNewWallet: () -> Void
    let onExistingWallet: () -> Void
    let onWatchWallet: () -> Void

    var body: some View {
        ListSection {
            row(icon: "plus", title: "add_wallet.new_wallet".localized, description: "add_wallet.new_wallet.description".localized, action: onNewWallet)
            row(icon: "arrow_in", title: "add_wallet.existing_wallet".localized, description: "add_wallet.existing_wallet.description".localized, action: onExistingWallet)
            row(icon: "eye_on", title: "add_wallet.watch_wallet".localized, description: "add_wallet.watch_wallet.description".localized, action: onWatchWallet)
        }
    }

    @ViewBuilder private func row(icon: String, title: String, description: String, action: @escaping () -> Void) -> some View {
        Cell(
            left: {
                ThemeImage(icon, size: 24)
            },
            middle: {
                MultiText(title: title, subtitle: description)
            },
            right: {
                Image.disclosureIcon
            },
            action: action
        )
    }
}
