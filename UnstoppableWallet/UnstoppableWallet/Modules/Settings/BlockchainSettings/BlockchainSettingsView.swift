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
                        ClickableRow(action: {
                            Coordinator.shared.present { _ in
                                ThemeNavigationStack { BtcBlockchainSettingsModule.view(blockchain: item.blockchain) }
                            }
                            stat(page: .blockchainSettings, event: .openBlockchainSettingsBtc(chainUid: item.blockchain.uid))
                        }) {
                            ItemView(
                                blockchain: item.blockchain,
                                value: item.title
                            )
                        }
                    }
                }

                ListSection {
                    ForEach(viewModel.evmItems, id: \.blockchain.uid) { item in
                        ClickableRow(action: {
                            Coordinator.shared.present { _ in
                                EvmNetworkView(blockchain: item.blockchain).ignoresSafeArea()
                            }
                            stat(page: .blockchainSettings, event: .openBlockchainSettingsEvm(chainUid: item.blockchain.uid))
                        }) {
                            ItemView(
                                blockchain: item.blockchain,
                                value: item.syncSource.name
                            )
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("blockchain_settings.title".localized)
    }

    struct ItemView: View {
        let blockchain: Blockchain
        let value: String

        var body: some View {
            KFImage.url(URL(string: blockchain.type.imageUrl))
                .resizable()
                .frame(width: .iconSize32, height: .iconSize32)

            VStack(spacing: 1) {
                Text(blockchain.name).themeBody()
                Text(value).themeSubhead2()
            }

            Image.disclosureIcon
        }
    }
}
