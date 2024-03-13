import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapTokenSelectView: View {
    @StateObject private var viewModel: MultiSwapTokenSelectViewModel

    @Binding var currentToken: Token?
    @Binding var isPresented: Bool

    init(currentToken: Binding<Token?>, otherToken: Token?, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: MultiSwapTokenSelectViewModel(token: otherToken))
        _currentToken = currentToken
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                VStack(spacing: 0) {
                    SearchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)

                    ThemeList(items: viewModel.items) { item in
                        ClickableRow(action: {
                            currentToken = item.token
                            isPresented = false
                        }) {
                            KFImage.url(URL(string: item.token.coin.imageUrl))
                                .resizable()
                                .placeholder {
                                    Image(item.token.placeholderImageName)
                                }
                                .frame(width: .iconSize32, height: .iconSize32)

                            VStack(spacing: 1) {
                                HStack(spacing: .margin8) {
                                    Text(item.token.coin.code).textBody()

                                    if let badge = item.token.badge {
                                        BadgeViewNew(text: badge)
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
                    .themeListStyle(.transparent)
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
    }
}
