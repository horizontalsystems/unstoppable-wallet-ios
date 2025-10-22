import SwiftUI

struct TronReceiveAddressView: View {
    @StateObject var viewModel: TronReceiveAddressViewModel
    private var onDismiss: (() -> Void)? = nil

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss

        _viewModel = StateObject(
            wrappedValue: TronReceiveAddressViewModel(
                service: TronReceiveAddressService(wallet: wallet),
                viewItemFactory: TronReceiveAddressViewItemFactory(),
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
                MiddleTextIcon(text: "deposit.account".localized, icon: "info_filled")
            }, right: {
                ThemeText("deposit.not_active".localized, style: .subheadSB, colorStyle: .yellow)
            }
        ) {
            Coordinator.shared.present(info: .init(title: "deposit.not_active.title".localized, description: "deposit.not_active.tron_description".localized))
        }
    }
}
