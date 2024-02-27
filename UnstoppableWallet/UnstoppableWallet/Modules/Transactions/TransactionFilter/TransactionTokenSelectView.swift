import Kingfisher
import MarketKit
import SwiftUI

struct TransactionTokenSelectView: View {
    @ObservedObject var viewModel: TransactionTokenSelectViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var searchText: String = ""

    init(transactionFilterViewModel: TransactionFilterViewModel) {
        _viewModel = ObservedObject(wrappedValue: TransactionTokenSelectViewModel(transactionFilterViewModel: transactionFilterViewModel))
    }

    var body: some View {
        ThemeView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, prompt: "placeholder.search".localized)

                ScrollableThemeView {
                    ListSection {
                        ClickableRow(action: {
                            viewModel.set(currentToken: nil)
                            presentationMode.wrappedValue.dismiss()
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
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                KFImage.url(URL(string: token.coin.imageUrl))
                                    .resizable()
                                    .placeholder { Image(token.placeholderImageName) }
                                    .frame(width: .iconSize32, height: .iconSize32)

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
                    presentationMode.wrappedValue.dismiss()
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
