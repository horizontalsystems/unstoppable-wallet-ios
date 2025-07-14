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
        ThemeView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, prompt: "placeholder.search".localized)

                ScrollableThemeView {
                    ListSection {
                        ClickableRow(action: {
                            viewModel.set(currentToken: nil)
                            isPresented = false
                        }) {
                            Image("circle_coin_24").themeIcon()
                            Text("transaction_filter.all_coins").themeBody()

                            if viewModel.currentToken == nil {
                                Image.checkIcon
                            }
                        }

                        ForEach(searchResults, id: \.self) { token in
                            ClickableRow(action: {
                                viewModel.set(currentToken: token)
                                isPresented = false
                            }) {
                                CoinIconView(coin: token.coin, placeholderImage: token.placeholderImageName)

                                VStack(spacing: 1) {
                                    HStack(spacing: .margin8) {
                                        Text(token.coin.code).textBody()

                                        if let badge = token.badge {
                                            BadgeViewNew(text: badge)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    Text(token.coin.name).themeSubhead2()
                                }

                                if viewModel.currentToken == token {
                                    Image.checkIcon
                                }
                            }
                        }
                    }
                    .themeListStyle(.transparent)
                    .padding(.bottom, .margin32)
                }
            }
            .navigationTitle("transaction_filter.coin".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    isPresented = false
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
