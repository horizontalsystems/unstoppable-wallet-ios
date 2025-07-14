import MarketKit
import SwiftUI

struct CheckAddressView: View {
    @StateObject var viewModel = CheckAddressViewModel()

    @Environment(\.presentationMode) private var presentationMode

    var borderColor: Color {
        switch viewModel.addressResult {
        case .invalid: return .themeLucian
        default: return .themeBlade
        }
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin16) {
                AddressViewNew(
                    initial: .init(showContacts: false),
                    text: $viewModel.address,
                    result: $viewModel.addressResult,
                    borderColor: Binding(get: { borderColor }, set: { _ in })
                )
                .padding(.bottom, .margin12)

                switch viewModel.state {
                case .idle, .valid:
                    EmptyView()
                case let .invalid(caution):
                    if let caution {
                        VStack(spacing: .margin12) {
                            HighlightedTextView(caution: caution)
                        }
                        .padding(.top, .margin16)
                    }
                }

                VStack(spacing: .margin24) {
                    ListSection {
                        ClickableRow(spacing: .margin8, action: {
                            Coordinator.shared.present(info: .init(title: "Chainalysis.com", description: "check_address.chainalysis.description".localized))
                        }) {
                            HStack(spacing: .margin16) {
                                Image("chainalysis_32")
                                Text("Chainalysis.com").textSubhead1()
                            }
                            Spacer()
                            Image("circle_information_20").themeIcon()
                        }

                        checkView(title: "check_address.sanctions_check".localized, state: viewModel.checkStates[.chainalysis] ?? .idle)
                    }
                    .themeListStyle(.bordered)

                    ListSection {
                        ClickableRow(spacing: .margin8, action: {
                            Coordinator.shared.present(info: .init(title: "Hashdit.io", description: "check_address.hashdit.description".localized))
                        }) {
                            HStack(spacing: .margin16) {
                                Image("hashdit_32")
                                Text("Hashdit.io").textSubhead1()
                            }
                            Spacer()
                            Image("circle_information_20").themeIcon()
                        }

                        VStack(spacing: 0) {
                            ForEach(viewModel.hashDitBlockchains) { blockchain in
                                checkView(title: "check_address.on_blockchain".localized(blockchain.name), state: viewModel.checkStates[.hashdit(blockchainType: blockchain.type)] ?? .idle)
                            }
                        }
                    }
                    .themeListStyle(.bordered)

                    ForEach(viewModel.contractFullCoins) { fullCoin in
                        ListSection {
                            ClickableRow(spacing: .margin8, action: {
                                Coordinator.shared.present(info: .init(
                                    title: "check_address.coin_blacklist_check".localized(fullCoin.coin.code),
                                    description: "check_address.coin_blacklist.description".localized(fullCoin.coin.name, fullCoin.coin.code, fullCoin.coin.code)
                                ))
                            }) {
                                HStack(spacing: .margin16) {
                                    CoinIconView(coin: fullCoin.coin)
                                    Text("check_address.coin_blacklist_check".localized(fullCoin.coin.code)).textSubhead1()
                                }
                                Spacer()
                                Image("circle_information_20").themeIcon()
                            }

                            VStack(spacing: 0) {
                                ForEach(fullCoin.tokens, id: \.blockchain.uid) { token in
                                    checkView(title: "check_address.on_blockchain".localized(token.blockchain.name), state: viewModel.checkStates[.contract(token: token)] ?? .idle)
                                }
                            }
                        }
                        .themeListStyle(.bordered)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("address.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.close".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    @ViewBuilder private func checkView(title: String, state: CheckAddressViewModel.CheckState) -> some View {
        HStack(spacing: .margin8) {
            Text(title).textSubhead2()

            Spacer()

            switch state {
            case .idle:
                Text("-").textSubhead2()
            case .checking:
                ProgressView()
            case .clear:
                Text("send.address.check.clear".localized).textSubhead2(color: .themeRemus)
            case .detected:
                Text("send.address.check.detected".localized).textSubhead2(color: .themeLucian)
            case .notAvailable:
                Text("n/a".localized).textSubhead2()
            }
        }
        .padding(.horizontal, .margin16)
        .frame(minHeight: 40)
    }
}
