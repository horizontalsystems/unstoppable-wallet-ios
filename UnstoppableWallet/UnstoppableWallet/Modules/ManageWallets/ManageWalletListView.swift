import Kingfisher
import MarketKit
import SwiftUI

struct ManageWalletListView: View {
    @ObservedObject var viewModel: ManageWalletsViewModel

    var body: some View {
        VStack(spacing: 0) {
            ListForEachIdentifiable(viewModel.items) { item in
                view(item: item, forceToggleOn: nil)
            }
        }
    }

    @ViewBuilder private func view(item: ManageWalletsViewModel.Item, forceToggleOn _: Bool? = nil) -> some View {
        Cell(
            left: {
                CoinIconView(coin: item.token.coin)
            },
            middle: {
                MultiText(title: item.token.coin.code, badge: item.token.badge, subtitle: item.token.coin.name)
            },
            right: {
                HStack(spacing: .margin12) {
                    if item.hasInfo {
                        IconButton(icon: "information", style: .secondary, mode: .transparent, size: .small) {
                            showInfo(item: item)
                        }
                    }

                    ThemeToggle(isOn: Binding(get: {
                        viewModel.enabledTokens[item.id] ?? false
                    }, set: { isEnabled in
                        viewModel.toggle(item: item, enabled: isEnabled)
                    }).animation(), style: .yellow)
                }
            }
        )
    }

    private func showInfo(item: ManageWalletsViewModel.Item) {
        guard let infoItem = viewModel.showInfo(item: item) else {
            return
        }

        switch infoItem.type {
        case .derivation, .bitcoinCashCoinType: showDescription(coin: infoItem.token.coin, type: infoItem.type)
        case let .birthdayHeight(height): showBirthdayHeight(coin: infoItem.token.coin, height: height)
        case let .contractAddress(value, explorerUrl): showContract(token: infoItem.token, value: value, explorerUrl: explorerUrl)
        }
    }

    private func showDescription(coin: Coin, type: ManageWalletsTokenInfoProvider.InfoType) {
        let text: String
        switch type {
        case .derivation:
            text = "manage_wallets.derivation_description".localized(coin.name, AppConfig.appName, coin.name)
        case .bitcoinCashCoinType:
            text = "manage_wallets.bitcoin_cash_coin_type_description".localized(AppConfig.appName)
        default:
            return
        }

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(items: [
                .title(icon: ComponentImage(url: coin.imageUrl), title: coin.code),
                .footer(text: text),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "button.close".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ])
        }
    }

    private func showBirthdayHeight(coin: Coin, height: Int) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(items: [
                .title(icon: ComponentImage(url: coin.imageUrl), title: coin.code),
                .list(items: [
                    .init(title: "birthday_height.title".localized, value: ComponentCopyableValue(height.description)),
                ]),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "button.close".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ])
        }
    }

    private func showContract(token: Token, value: String, explorerUrl: String?) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(items: [
                .title(icon: ComponentImage(url: token.coin.imageUrl), title: token.coin.code),
                .customList(views: [
                    AnyView(contractRow(token: token, value: value, explorerUrl: explorerUrl)),
                ]),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "button.close".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ])
        }
    }

    @ViewBuilder private func contractRow(token: Token, value: String, explorerUrl: String?) -> some View {
        Cell(
            left: {
                KFImage.url(URL(string: token.blockchain.type.imageUrl))
                    .resizable()
                    .frame(width: .iconSize32, height: .iconSize32)
            },
            middle: {
                MiddleTextIcon(text: value)
            },
            right: {
                if let explorerUrl {
                    Button {
                        open(url: explorerUrl, statPage: .manageWallets)
                    } label: {
                        Image("globe_20").renderingMode(.template)
                    }
                    .buttonStyle(SecondaryCircleButtonStyle())
                }
            }
        )
    }

    private func open(url: String, statPage: StatPage) {
        guard let url = URL(string: url) else {
            return
        }

        Coordinator.shared.present(url: url)

        stat(page: .info, event: .open(page: statPage))
    }
}
