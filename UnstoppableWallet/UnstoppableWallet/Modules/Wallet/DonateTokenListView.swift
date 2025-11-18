import SwiftUI

struct DonateTokenListView: View {
    @StateObject private var viewModel: SendTokenListViewModel

    @State private var path = NavigationPath()

    @Binding var isPresented: Bool
    @State var addressesPresented = false

    init(isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: SendTokenListViewModel(options: .init()))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView {
                VStack(spacing: 0) {
                    ThemeList(bottomSpacing: .margin16) {
                        VStack(spacing: .margin24) {
                            Text("donate.support.description".localized)
                                .textHeadline2()
                                .multilineTextAlignment(.center)
                            Image("heart_fill_24").themeIcon(color: .themeJacob)
                            Button(action: {
                                addressesPresented = true
                            }) {
                                Text("donate.list.get_address".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .gray))
                            Text("donate.support.bottom_description".localized).textSubhead2()
                        }
                        .padding(.vertical, .margin24)
                        .padding(.horizontal, .margin32)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)

                        let items = viewModel.items

                        ListForEach(items) { item in
                            WalletListItemView(item: item, balancePrimaryValue: viewModel.balancePrimaryValue, balanceHidden: viewModel.balanceHidden, amountRounding: viewModel.amountRounding, subtitleMode: .coinName, isReachable: viewModel.isReachable) {
                                guard let address = AppConfig.donationAddresses.first(where: { $0.key == item.wallet.token.blockchainType })?.value else {
                                    return
                                }

                                path.append(DestinationData(wallet: item.wallet, address: address))
                                stat(page: .sendTokenList, event: .openSend(token: item.wallet.token))
                            } failedAction: {
                                Coordinator.shared.presentBalanceError(wallet: item.wallet, state: item.state)
                            }
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $addressesPresented) {
                DonateAddressesView()
            }
            .navigationDestination(for: DestinationData.self) { data in
                let resolvedAddress = ResolvedAddress(address: data.address, issueTypes: [])
                PreSendView(
                    wallet: data.wallet,
                    handler: SendHandlerFactory.preSendHandler(wallet: data.wallet, address: resolvedAddress),
                    resolvedAddress: resolvedAddress,
                    addressVisible: false,
                    path: $path,
                    onDismiss: {
                        isPresented = false
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("donate.list.title".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension DonateTokenListView {
    struct DestinationData: Hashable {
        let wallet: Wallet
        let address: String
    }
}
