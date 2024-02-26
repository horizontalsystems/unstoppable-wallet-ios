import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapTokenSelectView: View {
    @Binding var token: Token?
    @Binding var isPresented: Bool

    @StateObject private var viewModel = MultiSwapTokenSelectViewModel()

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                VStack(spacing: 0) {
                    SearchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)

                    ThemeList(items: viewModel.items) { item in
                        ClickableRow(action: {
                            token = item.token
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

                                        Text(balance).textBody()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: .margin8) {
                                    Text(item.token.coin.name).themeSubhead2()

                                    if let fiatBalance = item.fiatBalance {
                                        Spacer()

                                        Text(fiatBalance).textSubhead2()
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
