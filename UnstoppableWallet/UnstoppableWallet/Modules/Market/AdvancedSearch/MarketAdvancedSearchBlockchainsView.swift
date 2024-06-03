import Kingfisher
import MarketKit
import SwiftUI

struct MarketAdvancedSearchBlockchainsView: View {
    @ObservedObject var viewModel: MarketAdvancedSearchViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationView {
            ScrollableThemeView {
                VStack(spacing: .margin24) {
                    ListSection {
                        ClickableRow {
                            viewModel.blockchains = Set()
                        } content: {
                            Text("selector.any".localized).themeBody(color: .themeGray)

                            if viewModel.blockchains.isEmpty {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }

                        ForEach(viewModel.allBlockchains) { blockchain in
                            ClickableRow {
                                if viewModel.blockchains.contains(blockchain) {
                                    viewModel.blockchains.remove(blockchain)
                                } else {
                                    viewModel.blockchains.insert(blockchain)
                                }
                            } content: {
                                KFImage.url(URL(string: blockchain.type.imageUrl))
                                    .resizable()
                                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeSteel20) }
                                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                                    .frame(width: .iconSize32, height: .iconSize32)

                                Text(blockchain.name).themeBody()

                                if viewModel.blockchains.contains(blockchain) {
                                    Image("check_1_20").themeIcon(color: .themeJacob)
                                }
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("market.advanced_search.blockchains".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.done".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
