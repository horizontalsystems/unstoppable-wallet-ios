import MarketKit
import SDWebImageSwiftUI
import SwiftUI

struct BlockchainSettingsView: View {
    @ObservedObject var viewModel: BlockchainSettingsViewModel

    @State private var btcSheetBlockchain: Blockchain?
    @State private var evmSheetBlockchain: Blockchain?

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                ListSection {
                    ForEach(viewModel.btcItems, id: \.blockchain.uid) { item in
                        ClickableRow(action: {
                            btcSheetBlockchain = item.blockchain
                        }) {
                            ItemView(
                                blockchain: item.blockchain,
                                value: item.restoreMode.title
                            )
                        }
                    }
                    .sheet(item: $btcSheetBlockchain) { blockchain in
                        ThemeNavigationView { BtcBlockchainSettingsModule.view(blockchain: blockchain) }
                    }
                }

                ListSection {
                    ForEach(viewModel.evmItems, id: \.blockchain.uid) { item in
                        ClickableRow(action: {
                            evmSheetBlockchain = item.blockchain
                        }) {
                            ItemView(
                                blockchain: item.blockchain,
                                value: item.syncSource.name
                            )
                        }
                    }
                    .sheet(item: $evmSheetBlockchain) { blockchain in
                        EvmNetworkView(blockchain: blockchain)
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
            WebImage(url: URL(string: blockchain.type.imageUrl))
                .resizable()
                .scaledToFit()
                .frame(width: .iconSize32, height: .iconSize32)

            VStack(spacing: 1) {
                Text(blockchain.name).themeBody()
                Text(value).themeSubhead2()
            }

            Image.disclosureIcon
        }
    }
}
