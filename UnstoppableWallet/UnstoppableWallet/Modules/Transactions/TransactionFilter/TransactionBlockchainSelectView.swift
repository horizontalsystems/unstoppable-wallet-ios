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
                ClickableRow(action: {
                    viewModel.set(currentBlockchain: nil)
                    isPresented = false
                }) {
                    Image("blocks_24").themeIcon()
                    Text("transaction_filter.all_blockchains").themeBody()

                    if viewModel.currentBlockchain == nil {
                        Image.checkIcon
                    }
                }

                ForEach(viewModel.blockchains, id: \.uid) { blockchain in
                    ClickableRow(action: {
                        viewModel.set(currentBlockchain: blockchain)
                        isPresented = false
                    }) {
                        KFImage.url(URL(string: blockchain.type.imageUrl))
                            .resizable()
                            .frame(width: .iconSize32, height: .iconSize32)

                        Text(blockchain.name).themeBody()

                        if viewModel.currentBlockchain == blockchain {
                            Image.checkIcon
                        }
                    }
                }
            }
            .themeListStyle(.transparent)
            .padding(.bottom, .margin32)
        }
        .navigationTitle("transaction_filter.blockchain".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                isPresented = false
            }
        }
    }
}
