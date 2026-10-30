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
                                Cell(
                                    middle: { ThemeText("selector.any".localized, style: .headline2, colorStyle: .secondary) },
                                    right: {
                                        if viewModel.blockchains.isEmpty {
                                            Image.checkIcon
                                        }
                                    },
                                    action: {
                                        viewModel.blockchains = Set()
                                    }
                                )

                                ForEach(viewModel.allBlockchains) { blockchain in
                                    Cell(
                                        middle: { ThemeText(blockchain.name, style: .headline2) },
                                        right: {
                                            if viewModel.blockchains.contains(blockchain) {
                                                Image.checkIcon
                                            }
                                        },
                                        action: {
                                            if viewModel.blockchains.contains(blockchain) {
                                                viewModel.blockchains.remove(blockchain)
                                            } else {
                                                viewModel.blockchains.insert(blockchain)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                } bottomContent: {
                    ThemeButton(text: buttonTitle()) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("market.advanced_search.blockchains".localized)
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

    func buttonTitle() -> String {
        viewModel.blockchains.count > 0 ? ["button.select".localized, viewModel.blockchains.count.description].joined(separator: " ") : "button.done".localized
    }
}
