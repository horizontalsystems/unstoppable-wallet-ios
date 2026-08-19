import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapTokenSelectView: View {
    private let title: String

    @StateObject private var viewModel: MultiSwapTokenSelectViewModel

    @Binding var currentToken: Token?
    @Binding var isPresented: Bool

    init(title: String, currentToken: Binding<Token?>, otherToken: Token?, allowExternalReceive: Bool = false, isPresented: Binding<Bool>) {
        self.title = title
        _viewModel = .init(wrappedValue: MultiSwapTokenSelectViewModel(token: otherToken, allowExternalReceive: allowExternalReceive))
        _currentToken = currentToken
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                ContentView(viewModel: viewModel) { token in
                    viewModel.handleSelection(token: token)
                    currentToken = token
                    isPresented = false
                }
            }
            .navigationTitle(title)
            .searchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)
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

    private struct ContentView: View {
        @ObservedObject var viewModel: MultiSwapTokenSelectViewModel
        let select: (Token) -> Void

        @Environment(\.isSearching) private var isSearching

        var body: some View {
            Group {
                if viewModel.searching, viewModel.searchResults.isEmpty {
                    PlaceholderViewNew(icon: "warning_filled", subtitle: "alert.not_founded".localized)
                } else {
                    list()
                }
            }
            .background {
                // search states are drawn on the cell color, not the page background
                if viewModel.searchActive || viewModel.searching {
                    Color.themeLawrence.ignoresSafeArea()
                }
            }
            .onChange(of: isSearching) { _, active in
                viewModel.searchActive = active
            }
        }

        @ViewBuilder private func list() -> some View {
            ThemeList(bottomSpacing: .margin16) {
                if viewModel.searching {
                    ListForEach(viewModel.searchResults) { item in
                        row(item)
                    }
                } else if viewModel.searchActive {
                    if !viewModel.recent.isEmpty {
                        Section {
                            ListForEach(viewModel.recent) { item in
                                row(item)
                            }
                        } header: {
                            ThemeListSectionHeader(text: "swap.token_select.recent".localized)
                        }
                    }
                } else {
                    if !viewModel.popular.isEmpty {
                        Section {
                            popularRow()
                        } header: {
                            ThemeListSectionHeader(text: "swap.token_select.popular_tokens".localized)
                        }
                    }

                    if !viewModel.yourTokens.isEmpty {
                        Section {
                            ListForEach(viewModel.yourTokens) { item in
                                row(item)
                            }
                        } header: {
                            ThemeListSectionHeader(text: "swap.token_select.your_tokens".localized)
                        }
                    }

                    if !viewModel.topTokens.isEmpty {
                        Section {
                            ListForEach(viewModel.topTokens) { item in
                                row(item)
                            }
                        } header: {
                            ThemeListSectionHeader(text: "swap.token_select.top_tokens".localized)
                        }
                    }
                }
            }
        }

        @ViewBuilder private func popularRow() -> some View {
            VStack(spacing: 0) {
                HorizontalDivider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .margin8) {
                        ForEach(viewModel.popular, id: \.self) { item in
                            Button(action: {
                                select(item.token)
                            }) {
                                // The chain badge sticks out past the coin icon, so it absorbs
                                // half of the icon-to-text gap.
                                HStack(spacing: 6) {
                                    chipIcon(token: item.token)

                                    ThemeText(item.token.coin.code, style: .captionSB, colorStyle: .primary)
                                }
                                .padding(.leading, .margin12)
                                .padding(.trailing, .margin16)
                                .frame(height: 36)
                                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.themeBlade))
                            }
                        }
                    }
                    .padding(.horizontal, .margin16)
                    .padding(.vertical, .margin8)
                }

                HorizontalDivider()
            }
            .listRowInsets(EdgeInsets())
            .background(Color.themeLawrence)
        }

        // 20pt coin circle; non-native tokens get a 10pt chain badge on a 12pt background-colored plate
        @ViewBuilder private func chipIcon(token: Token) -> some View {
            ZStack(alignment: .bottomTrailing) {
                CoinIconView(coin: token.coin, placeholderImage: token.placeholderImageName, size: 20)

                if !token.type.isNative {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.themeBlade)
                        .frame(width: 12, height: 12)
                        .overlay(
                            KFImage.url(URL(string: token.blockchainType.imageUrl))
                                .resizable()
                                .frame(width: 10, height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                        )
                        .offset(x: 3.5, y: 3.5)
                }
            }
        }

        @ViewBuilder private func row(_ item: MultiSwapTokenSelectViewModel.Item) -> some View {
            ClickableRow(action: {
                select(item.token)
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
}
