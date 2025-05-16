import Kingfisher
import MarketKit
import SwiftUI
import ThemeKit

struct MarketView: View {
    @StateObject var searchViewModel: MarketSearchViewModel
    @StateObject var globalViewModel: MarketGlobalViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel

    @FocusState var searchFocused: Bool
    @State private var advancedSearchPresented = false

    init() {
        _searchViewModel = StateObject(wrappedValue: MarketSearchViewModel())
        _globalViewModel = StateObject(wrappedValue: MarketGlobalViewModel())
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .markets, section: .coins))
    }

    var body: some View {
        ThemeView {
            VStack(spacing: 0) {
                SearchBarWithCancel(text: $searchViewModel.searchText, prompt: "placeholder.search".localized, focused: $searchFocused)

                ZStack {
                    VStack(spacing: 0) {
                        MarketGlobalView(viewModel: globalViewModel)
                        MarketTabView(watchlistViewModel: watchlistViewModel)
                    }

                    if searchFocused {
                        MarketSearchView(viewModel: searchViewModel, watchlistViewModel: watchlistViewModel)
                            .onFirstAppear { stat(page: .markets, event: .open(page: .marketSearch)) }
                    }
                }
            }
        }
        .navigationTitle("market.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    stat(page: .markets, event: .open(page: .advancedSearch))
                    advancedSearchPresented = true
                }) {
                    Image("search_24")
                        .renderingMode(.template)
                        .foregroundColor(.themeGray)
                }
            }
        }
        .sheet(isPresented: $advancedSearchPresented) {
            MarketAdvancedSearchView(isPresented: $advancedSearchPresented)
        }
    }
}
