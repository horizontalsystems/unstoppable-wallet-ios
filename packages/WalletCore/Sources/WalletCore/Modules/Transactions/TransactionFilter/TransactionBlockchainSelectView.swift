import Kingfisher
import SwiftUI

struct TransactionBlockchainSelectView: View {
    @ObservedObject var viewModel: TransactionBlockchainSelectViewModel
    @Binding var isPresented: Bool

    init(transactionFilterViewModel: TransactionFilterViewModel, isPresented: Binding<Bool>) {
        _viewModel = ObservedObject(wrappedValue: TransactionBlockchainSelectViewModel(transactionFilterViewModel: transactionFilterViewModel))
        _isPresented = isPresented
    }

    var body: some View {
        ScrollableThemeView {
            ListSection {
                Cell(
                    left: { ThemeImage("blocks", size: .iconSize24) },
                    middle: { ThemeText("transaction_filter.all_blockchains".localized, style: .headline2) },
                    right: {
                        if viewModel.currentBlockchain == nil {
                            Image.checkIcon
                        }
                    },
                    action: {
                        viewModel.set(currentBlockchain: nil)
                        isPresented = false
                    }
                )

                ForEach(viewModel.blockchains, id: \.uid) { blockchain in
                    Cell(
                        left: { BlockchainIcon(blockchain: blockchain) },
                        middle: { ThemeText(blockchain.name, style: .headline2) },
                        right: {
                            if viewModel.currentBlockchain == blockchain {
                                Image.checkIcon
                            }
                        },
                        action: {
                            viewModel.set(currentBlockchain: blockchain)
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
