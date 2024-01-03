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

                    ThemeList(items: viewModel.tokens) { token in
                        ClickableRow(action: {
                            self.token = token
                            isPresented = false
                        }) {
                            KFImage.url(URL(string: token.coin.imageUrl))
                                .resizable()
                                .placeholder {
                                    Image(token.placeholderImageName)
                                }
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

                            if self.token == token {
                                Image.checkIcon
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
