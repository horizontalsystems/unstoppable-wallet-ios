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
                viewItemFactory: ReceiveAddressViewItemFactory(),
                decimalParser: AmountDecimalParser()
            )
        )
    }

    var body: some View {
        BaseReceiveAddressView(viewModel: viewModel, content: {}, onDismiss: onDismiss)
    }
}
