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
                        Cell(
                            left: { BlockchainIcon(blockchain: blockchain) },
                            middle: { ThemeText(blockchain.name, style: .headline2) },
                            right: {
                                if viewModel.currentBlockchainItem.blockchain == blockchain {
                                    Image.checkIcon
                                }
                            },
                            action: {
                                viewModel.set(blockchain: blockchain)
                                isPresented = false
                            }
                        )
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
