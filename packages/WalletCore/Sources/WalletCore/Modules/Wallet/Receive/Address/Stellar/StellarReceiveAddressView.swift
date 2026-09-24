import SwiftUI

struct StellarReceiveAddressView: View {
    @StateObject var viewModel: StellarReceiveAddressViewModel
    private var onDismiss: (() -> Void)? = nil
    // the warning stays — an incoming transfer to a non-activated asset is rejected — but a watch account
    // cannot sign the activation, so the row does not open the popup
    private let watchAccount: Bool

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        watchAccount = wallet.account.watchAccount

        _viewModel = StateObject(
            wrappedValue: StellarReceiveAddressViewModel(
                service: StellarReceiveAddressService(wallet: wallet),
                viewItemFactory: StellarReceiveAddressViewItemFactory()
            )
        )
    }

    var body: some View {
        BaseReceiveAddressView(viewModel: viewModel, content: { [weak viewModel] in
            if let viewModel, let activated = viewModel.activated.data, !activated {
                notActive()
            }
        }, onDismiss: onDismiss)
    }

    @ViewBuilder func notActive() -> some View {
        Cell(
            middle: {
                MiddleTextIcon(text: "deposit.trustline".localized, icon: "info_filled")
            }, right: {
                ThemeText("deposit.trustline.not_activated".localized, style: .subheadSB, colorStyle: .yellow)
            },
            action: watchAccount ? nil : { viewModel.showPopup() }
        )
    }
}
