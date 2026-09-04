import Kingfisher
import SwiftUI

struct WatchSelectView: View {
    let items: WatchViewModel.Items
    let onSelect: ([String]) -> Void

    @State private var enabledUids = Set<String>()

    var body: some View {
        ThemeView(style: .list) {
            BottomGradientWrapper(gradientColor: .themeLawrence) {
                switch items {
                case let .blockchains(blockchains):
                    ThemeList(blockchains, bottomSpacing: 16) { blockchain in
                        Cell(
                            left: {
                                BlockchainIcon(blockchain: blockchain)
                            },
                            middle: {
                                MultiText(
                                    title: blockchain.name,
                                    subtitle: blockchain.type.description
                                )
                            },
                            right: {
                                let uid = blockchain.uid

                                Toggle(isOn: Binding(
                                    get: {
                                        enabledUids.contains(uid)
                                    },
                                    set: {
                                        if $0 {
                                            enabledUids.insert(uid)
                                        } else {
                                            enabledUids.remove(uid)
                                        }
                                    }
                                )) {}
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                            }
                        )
                    }
                case let .coins(tokens):
                    ThemeList(tokens, bottomSpacing: 16) { token in
                        Cell(
                            left: {
                                CoinIconView(coin: token.coin)
                            },
                            middle: {
                                MultiText(
                                    title: token.coin.code,
                                    badge: token.badge,
                                    subtitle: token.coin.name
                                )
                            },
                            right: {
                                let uid = token.tokenQuery.id

                                Toggle(isOn: Binding(
                                    get: {
                                        enabledUids.contains(uid)
                                    },
                                    set: {
                                        if $0 {
                                            enabledUids.insert(uid)
                                        } else {
                                            enabledUids.remove(uid)
                                        }
                                    }
                                )) {}
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                            }
                        )
                    }
                }
            } bottomContent: {
                ThemeButton(text: "watch_address.watch".localized) {
                    onSelect(Array(enabledUids))
                }
                .disabled(enabledUids.isEmpty)
            }
        }
        .navigationTitle(items.title)
    }
}
