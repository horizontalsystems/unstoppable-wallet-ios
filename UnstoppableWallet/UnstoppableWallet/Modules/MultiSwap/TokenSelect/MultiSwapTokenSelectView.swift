import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapTokenSelectView: View {
    private let title: String

    @StateObject private var viewModel: MultiSwapTokenSelectViewModel

    @Binding var currentToken: Token?
    @Binding var isPresented: Bool

    init(title: String, currentToken: Binding<Token?>, otherToken: Token?, isPresented: Binding<Bool>) {
        self.title = title
        _viewModel = .init(wrappedValue: MultiSwapTokenSelectViewModel(token: otherToken))
        _currentToken = currentToken
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                VStack(spacing: 0) {
                    SearchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)

                    ThemeList(viewModel.items, bottomSpacing: .margin16) { item in
                        ClickableRow(action: {
                            currentToken = item.token
                            isPresented = false
                        }) {
                            CoinIconView(coin: item.token.coin, placeholderImage: item.token.placeholderImageName)

                            VStack(spacing: 1) {
                                HStack(spacing: .margin8) {
                                    Text(item.token.coin.code).textBody()

                                    if let badge = item.token.badge {
                                        BadgeViewNew(badge)
                                    }

                                    if let balance = item.balance {
                                        Spacer()

                                        Text(balance)
                                            .textBody()
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: .margin8) {
                                    Text(item.token.coin.name).themeSubhead2()

                                    if let fiatBalance = item.fiatBalance {
                                        Spacer()

                                        Text(fiatBalance)
                                            .textSubhead2()
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
