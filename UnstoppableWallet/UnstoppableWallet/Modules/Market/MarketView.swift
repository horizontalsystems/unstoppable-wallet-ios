import Kingfisher
import MarketKit
import SwiftUI
import ThemeKit

struct MarketView: View {
    @StateObject var searchViewModel: MarketSearchViewModel
    @StateObject var globalViewModel: MarketGlobalViewModel

    @FocusState var searchFocused: Bool
    @State private var advancedSearchPresented = false

    init() {
        _searchViewModel = StateObject(wrappedValue: MarketSearchViewModel())
        _globalViewModel = StateObject(wrappedValue: MarketGlobalViewModel())
    }

    var body: some View {
        ThemeView {
            VStack(spacing: 0) {
                SearchBarWithCancel(text: $searchViewModel.searchText, prompt: "placeholder.search".localized, focused: $searchFocused)

                ZStack {
                    VStack(spacing: 0) {
                        MarketGlobalView(viewModel: globalViewModel)
                        MarketTabView()
                    }

                    if searchFocused {
                        MarketSearchView(viewModel: searchViewModel)
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
