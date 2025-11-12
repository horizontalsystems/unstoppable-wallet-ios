import SwiftUI

struct HDReceiveAddressView: View {
    @StateObject var viewModel: HDReceiveAddressViewModel
    private var onDismiss: (() -> Void)? = nil

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        let service = HDReceiveAddressService(wallet: wallet)

        _viewModel = StateObject(
            wrappedValue: HDReceiveAddressViewModel(
                service: service,
                viewItemFactory: ReceiveAddressViewItemFactory(),
                decimalParser: AmountDecimalParser()
            )
        )
    }

    var body: some View {
        BaseReceiveAddressView(viewModel: viewModel, content: { [weak viewModel] in
            if let viewModel,
               let usedAddressesData = viewModel.usedAddresses.data,
               let usedAddresses = usedAddressesData,
               !usedAddresses.isEmpty
            {
                NavigationRow(destination: {
                    UsedAddressesView(
                        coinName: viewModel.coinName,
                        title: "deposit.used_addresses.title".localized,
                        description: "deposit.used_addresses.description".localized(viewModel.coinName),
                        hasChangeAddresses: true,
                        usedAddresses: usedAddresses,
                        onDismiss: onDismiss ?? { presentationMode.wrappedValue.dismiss() }
                    )
                }) {
                    Text("deposit.used_addresses.title".localized).themeSubhead2()
                    Image.disclosureIcon
                }
            }
        }, onDismiss: onDismiss)
    }
}
