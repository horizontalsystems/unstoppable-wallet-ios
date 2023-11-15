import Kingfisher
import SwiftUI

struct TransactionBlockchainSelectView: View {
    @ObservedObject var viewModel: TransactionFilterViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            ListSection {
                ClickableRow(action: {
                    viewModel.set(blockchain: nil)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("blocks_24").themeIcon()
                    Text("transaction_filter.all_blockchains").themeBody()

                    if viewModel.blockchain == nil {
                        Image.checkIcon
                    }
                }

                ForEach(viewModel.blockchains, id: \.uid) { blockchain in
                    ClickableRow(action: {
                        viewModel.set(blockchain: blockchain)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        KFImage.url(URL(string: blockchain.type.imageUrl))
                            .resizable()
                            .frame(width: .iconSize32, height: .iconSize32)

                        Text(blockchain.name).themeBody()

                        if viewModel.blockchain == blockchain {
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
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
