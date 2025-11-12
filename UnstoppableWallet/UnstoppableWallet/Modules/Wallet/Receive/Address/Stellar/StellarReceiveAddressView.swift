import SwiftUI

struct StellarReceiveAddressView: View {
    @StateObject var viewModel: StellarReceiveAddressViewModel
    private var onDismiss: (() -> Void)? = nil

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss

        _viewModel = StateObject(
            wrappedValue: StellarReceiveAddressViewModel(
                service: StellarReceiveAddressService(wallet: wallet),
                viewItemFactory: StellarReceiveAddressViewItemFactory(),
                decimalParser: AmountDecimalParser()
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
            }
        ) {
            viewModel.showPopup()
        }
    }
}
