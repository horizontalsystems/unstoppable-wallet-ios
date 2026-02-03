import Kingfisher
import MarketKit
import SwiftUI

struct BlockchainSettingsView: View {
    @ObservedObject var viewModel: BlockchainSettingsViewModel

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                ListSection {
                    ForEach(viewModel.btcItems, id: \.blockchain.uid) { item in
                        ItemView(item: item)
                    }
                }

                ListSection {
                    ForEach(viewModel.evmItems, id: \.blockchain.uid) { item in
                        ItemView(item: item)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("blockchain_settings.title".localized)
    }

    struct ItemView: View {
        let item: BlockchainSettingsViewModel.Item

        var body: some View {
            ClickableRow(action: {
                switch item.type {
                case .evm:
                    Coordinator.shared.present { _ in
                        EvmNetworkView(blockchain: item.blockchain).ignoresSafeArea()
                    }

                    stat(page: .blockchainSettings, event: .openBlockchainSettingsEvm(chainUid: item.blockchain.uid))
                case .btc:
                    Coordinator.shared.present { _ in
                        ThemeNavigationStack { BtcBlockchainSettingsModule.view(blockchain: item.blockchain) }
                    }

                    stat(page: .blockchainSettings, event: .openBlockchainSettingsBtc(chainUid: item.blockchain.uid))
                case .monero:
                    Coordinator.shared.present { _ in
                        MoneroNetworkView(blockchain: item.blockchain).ignoresSafeArea()
                    }

                    stat(page: .blockchainSettings, event: .openBlockchainSettingsMonero)
                }

            }) {
                KFImage.url(URL(string: item.blockchain.type.imageUrl))
                    .resizable()
                    .frame(width: .iconSize32, height: .iconSize32)

                VStack(spacing: 1) {
                    Text(item.blockchain.name).themeBody()
                    Text(item.title).themeSubhead2()
                }

                Image.disclosureIcon
            }
        }
    }
}
