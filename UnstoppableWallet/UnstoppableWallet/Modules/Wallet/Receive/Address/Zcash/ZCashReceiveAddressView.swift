import SwiftUI

struct ZCashReceiveAddressView: View {
    @StateObject var viewModel: ZCashReceiveAddressViewModel
    private var onDismiss: (() -> Void)? = nil

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, addressType: ZcashAdapter.ReceiveAddressType, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        let service = ZCashReceiveAddressService(wallet: wallet, addressType: addressType)

        _viewModel = StateObject(
            wrappedValue: ZCashReceiveAddressViewModel(
                service: service,
                viewItemFactory: ReceiveAddressViewItemFactory(),
                decimalParser: AmountDecimalParser()
            )
        )
    }

    var body: some View {
        BaseReceiveAddressView(viewModel: viewModel, content: {}, onDismiss: onDismiss)
    }
}
