import SwiftUI

struct CoinPageView<Overview: View, Analytics: View, Markets: View>: View {
    @ObservedObject var viewModel: CoinPageViewModelNew

    @ViewBuilder let overviewView: Overview
    @ViewBuilder let analyticsView: Analytics
    @ViewBuilder let marketsView: Markets

    @Environment(\.presentationMode) private var presentationMode
    @State private var currentTabIndex: Int = Tab.overview.rawValue

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                VStack(spacing: 0) {
                    TabHeaderView(
                        tabs: Tab.allCases.map { $0.title },
                        currentTabIndex: $currentTabIndex
                    )

                    TabView(selection: $currentTabIndex) {
                        overviewView.tag(Tab.overview.rawValue)
                        analyticsView.tag(Tab.analytics.rawValue)
                        marketsView.tag(Tab.markets.rawValue)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle(viewModel.fullCoin.coin.code)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.close".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isFavorite.toggle()
                    }) {
                        Image(viewModel.isFavorite ? "filled_star_24" : "star_24")
                            .renderingMode(.template)
                            .foregroundColor(viewModel.isFavorite ? .themeJacob : .themeGray)
                    }
                }
            }
        }
    }
}

extension CoinPageView {
    enum Tab: Int, CaseIterable {
        case overview
        case analytics
        case markets

        var title: String {
            switch self {
            case .overview: return "coin_page.overview".localized
            case .analytics: return "coin_page.analytics".localized
            case .markets: return "coin_page.markets".localized
            }
        }
    }
}
