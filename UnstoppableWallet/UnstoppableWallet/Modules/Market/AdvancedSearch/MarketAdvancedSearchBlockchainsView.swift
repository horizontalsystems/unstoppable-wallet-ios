import Kingfisher
import MarketKit
import SwiftUI

struct MarketAdvancedSearchBlockchainsView: View {
    @ObservedObject var viewModel: MarketAdvancedSearchViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
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
                } bottomContent: {
                    Button(buttonTitle()) {
                        isPresented = false
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                }
            }
            .navigationTitle("market.advanced_search.blockchains".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    func buttonTitle() -> String {
        viewModel.blockchains.count > 0 ? ["button.select".localized, viewModel.blockchains.count.description].joined(separator: " ") : "button.done".localized
    }
}
