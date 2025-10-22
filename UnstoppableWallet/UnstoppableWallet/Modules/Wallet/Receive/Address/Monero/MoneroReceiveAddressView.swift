import SwiftUI

struct MoneroReceiveAddressView: View {
    @StateObject var viewModel: MoneroReceiveAddressViewModel
    private var onDismiss: (() -> Void)? = nil

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        let service = MoneroReceiveAddressService(wallet: wallet)

        _viewModel = StateObject(
            wrappedValue: MoneroReceiveAddressViewModel(
                service: service,
                viewItemFactory: ReceiveAddressViewItemFactory(),
                decimalParser: AmountDecimalParser()
            )
        )
    }

    var body: some View {
        BaseReceiveAddressView(viewModel: viewModel, content: { [weak viewModel] in
            if let viewModel,
               let subAddressesData = viewModel.subAddresses.data,
               let subAddresses = subAddressesData,
               !subAddresses.isEmpty
            {
                NavigationRow(destination: {
                    UsedAddressesView(
                        coinName: viewModel.coinName,
                        title: "deposit.subaddresses.title".localized,
                        description: "deposit.subaddresses.description".localized,
                        hasChangeAddresses: false,
                        usedAddresses: [.external: subAddresses],
                        onDismiss: onDismiss ?? { presentationMode.wrappedValue.dismiss() }
                    )
                }) {
                    Text("deposit.subaddresses.title".localized).themeSubhead2()
                    Image.disclosureIcon
                }
            }
        }, onDismiss: onDismiss)
    }
}
