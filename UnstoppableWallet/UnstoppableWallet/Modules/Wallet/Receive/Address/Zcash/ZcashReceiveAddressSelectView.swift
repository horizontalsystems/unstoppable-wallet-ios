import SwiftUI

struct ZcashReceiveAddressSelectView: View {
    @StateObject var viewModel: ZcashReceiveAddressSelectViewModel

    private let wallet: Wallet
    private var onDismiss: (() -> Void)?

    @Binding var path: NavigationPath

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, path: Binding<NavigationPath>, onDismiss: (() -> Void)? = nil) {
        self.wallet = wallet
        _path = path
        self.onDismiss = onDismiss

        _viewModel = StateObject(wrappedValue: ZcashReceiveAddressSelectViewModel())
    }

    var body: some View {
        ThemeView(style: .list) {
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
        }
        .navigationTitle("deposit.zcash.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ZcashAdapter.AddressType.self, destination: { addresType in
            destinationView(for: addresType)
        })
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
                path.append(viewItem.addressType)
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
