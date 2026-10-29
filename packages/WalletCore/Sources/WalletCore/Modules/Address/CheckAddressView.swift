import MarketKit
import SwiftUI

struct CheckAddressView: View {
    @StateObject private var viewModel = CheckAddressViewModel()
    @Binding var isPresented: Bool

    @Environment(\.addressParserFilter) private var parserFilter

    var borderColor: Color {
        switch viewModel.addressResult {
        case .invalid: return .themeLucian
        default: return .themeBlade
        }
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin16) {
                    AddressViewNew(
                        initial: .init(showContacts: false),
                        text: $viewModel.address,
                        result: $viewModel.addressResult,
                        parserFilter: parserFilter,
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
                            Cell(
                                left: { Image("chainalysis_32") },
                                middle: { ThemeText("Chainalysis.com", style: .subhead) },
                                right: { ThemeImage("information", size: .iconSize20) },
                                action: {
                                    Coordinator.shared.present(info: .init(title: "Chainalysis.com", description: "check_address.chainalysis.description".localized))
                                }
                            )

                            checkView(title: "check_address.sanctions_check".localized, state: viewModel.checkStates[.chainalysis] ?? .idle)
                        }
                        .themeListStyle(.bordered)

                        ListSection {
                            Cell(
                                left: { Image("hashdit_32") },
                                middle: { ThemeText("Hashdit.io", style: .subhead) },
                                right: { ThemeImage("information", size: .iconSize20) },
                                action: {
                                    Coordinator.shared.present(info: .init(title: "Hashdit.io", description: "check_address.hashdit.description".localized))
                                }
                            )

                            VStack(spacing: 0) {
                                ForEach(viewModel.hashDitBlockchains) { blockchain in
                                    checkView(title: "check_address.on_blockchain".localized(blockchain.name), state: viewModel.checkStates[.hashdit(blockchainType: blockchain.type)] ?? .idle)
                                }
                            }
                        }
                        .themeListStyle(.bordered)

                        ForEach(viewModel.contractFullCoins) { fullCoin in
                            ListSection {
                                Cell(
                                    left: { CoinIconView(coin: fullCoin.coin) },
                                    middle: { ThemeText("check_address.coin_blacklist_check".localized(fullCoin.coin.code), style: .subhead) },
                                    right: { ThemeImage("information", size: .iconSize20) },
                                    action: {
                                        Coordinator.shared.present(info: .init(
                                            title: "check_address.coin_blacklist_check".localized(fullCoin.coin.code),
                                            description: "check_address.coin_blacklist.description".localized(fullCoin.coin.name, fullCoin.coin.code, fullCoin.coin.code)
                                        ))
                                    }
                                )

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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
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
