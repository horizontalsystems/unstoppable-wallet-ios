import Kingfisher
import MarketKit
import SwiftUI

struct AddTokenBlockchainSelectView: View {
    @ObservedObject var viewModel: AddTokenViewModel
    @Binding var isPresented: Bool

    init(viewModel: AddTokenViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel

        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                ListSection {
                    ForEach(viewModel.blockchains, id: \.uid) { blockchain in
                        ClickableRow(action: {
                            viewModel.set(blockchain: blockchain)
                            isPresented = false
                        }) {
                            BlockchainIcon(blockchain: blockchain)
                            ThemeText(blockchain.name, style: .body)

                            Spacer()

                            if viewModel.currentBlockchainItem.blockchain == blockchain {
                                ThemeImage("check", size: .iconSize20, colorStyle: .yellow)
                            }
                        }
                    }
                }
                .themeListStyle(.transparent)
                .padding(.bottom, .margin32)
            }
            .navigationTitle("transaction_filter.blockchain".localized)
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
}
