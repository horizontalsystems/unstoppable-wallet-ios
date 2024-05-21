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
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel())
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
                    }
                }
            }
        }
        .navigationTitle("market.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    advancedSearchPresented = true
                }) {
                    Image("manage_2_24")
                        .renderingMode(.template)
                        .foregroundColor(.themeJacob)
                }
            }
        }
        .sheet(isPresented: $advancedSearchPresented) {
            MarketAdvancedSearchView().ignoresSafeArea()
        }
    }
}
