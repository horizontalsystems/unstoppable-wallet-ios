import SwiftUI

struct ZcashReceiveAddressSelectView: View {
    @StateObject var viewModel: ZcashReceiveAddressSelectViewModel

    private let wallet: Wallet
    private var onDismiss: (() -> Void)?

    @State private var selectedAddressType: ZcashAdapter.AddressType?
    @State private var isShowingDestination = false

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, onDismiss: (() -> Void)? = nil) {
        self.wallet = wallet
        self.onDismiss = onDismiss

        _viewModel = StateObject(wrappedValue: ZcashReceiveAddressSelectViewModel())
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                ThemeList {
                    Section {
                        ListForEach(viewModel.viewItems) { viewItem in
                            cell(viewItem: viewItem)
                        }
                    } header: {
                        ThemeText("deposit.zcash.header".localized, style: .subhead, colorStyle: .secondary)
                            .padding(.horizontal, .margin32)
                            .padding(.top, .margin12)
                            .padding(.bottom, .margin32)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.themeTyler)
                            .listRowInsets(EdgeInsets())
                    }
                }

                if let addressType = selectedAddressType { // TODO: remove code after deleting UIViewControllers from WalletView Receive Pages
                    NavigationLink(
                        destination: destinationView(for: addressType),
                        isActive: $isShowingDestination
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
        }
        .navigationTitle("deposit.zcash.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("button.cancel".localized) {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .accentColor(.themeGray)
    }

    @ViewBuilder private func cell(viewItem: ZcashReceiveAddressSelectViewModel.ViewItem) -> some View {
        Cell(
            middle: {
                MultiText(title: viewItem.title, subtitle: viewItem.description)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                selectedAddressType = viewItem.addressType
                isShowingDestination = true
            }
        )
    }

    @ViewBuilder
    private func destinationView(for addressType: ZcashAdapter.AddressType) -> some View {
        let service = ZCashReceiveAddressService(wallet: wallet, addressType: addressType)
        let viewModel = BaseReceiveAddressViewModel(
            service: service,
            viewItemFactory: ZCashReceiveAddressViewItemFactory(addressType: addressType),
            decimalParser: AmountDecimalParser()
        )

        BaseReceiveAddressView(viewModel: viewModel, content: {}, onDismiss: onDismiss)
            .navigationBarTitleDisplayMode(.inline)
    }
}
