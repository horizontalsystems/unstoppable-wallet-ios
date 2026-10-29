import Kingfisher
import MarketKit
import SwiftUI

struct TransactionTokenSelectView: View {
    @ObservedObject var viewModel: TransactionTokenSelectViewModel
    @Binding var isPresented: Bool

    @State private var searchText: String = ""

    init(transactionFilterViewModel: TransactionFilterViewModel, isPresented: Binding<Bool>) {
        _viewModel = ObservedObject(wrappedValue: TransactionTokenSelectViewModel(transactionFilterViewModel: transactionFilterViewModel))
        _isPresented = isPresented
    }

    var body: some View {
        ScrollableThemeView {
            ListSection {
                Cell(
                    left: { ThemeImage("circle_coin", size: .iconSize24) },
                    middle: { ThemeText("transaction_filter.all_coins".localized, style: .headline2) },
                    right: {
                        if viewModel.currentToken == nil {
                            Image.checkIcon
                        }
                    },
                    action: {
                        viewModel.set(currentToken: nil)
                        isPresented = false
                    }
                )

                ForEach(searchResults, id: \.self) { token in
                    Cell(
                        left: { CoinIconView(token: token) },
                        middle: { MultiText(title: token.coin.code, badge: token.badge, subtitle: token.coin.name) },
                        right: {
                            if viewModel.currentToken == token {
                                Image.checkIcon
                            }
                        },
                        action: {
                            viewModel.set(currentToken: token)
                            isPresented = false
                        }
                    )
                }
            }
            .themeListStyle(.transparent)
            .padding(.bottom, .margin32)
        }
        .navigationTitle("transaction_filter.coin".localized)
        .searchBar(text: $searchText, prompt: "placeholder.search".localized)
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

    var searchResults: [Token] {
        let text = searchText.trimmingCharacters(in: .whitespaces)

        if text.isEmpty {
            return viewModel.tokens
        } else {
            return viewModel.tokens.filter { token in
                token.coin.name.localizedCaseInsensitiveContains(text) || token.coin.code.localizedCaseInsensitiveContains(text)
            }
        }
    }
}
