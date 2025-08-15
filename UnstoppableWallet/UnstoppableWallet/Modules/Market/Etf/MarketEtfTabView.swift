import MarketKit
import SwiftUI

struct MarketEtfTabView: View {
    @StateObject private var viewModelFactory = MarketEtfViewModelFactory()
    @Binding var isPresented: Bool

    @State private var currentTab: MarketEtfFetcher.EtfCategory = .btc

    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView(style: .list) {
                TabHeaderView(
                    tabs: MarketEtfFetcher.EtfCategory.allCases.map(\.title),
                    currentTabIndex: Binding(
                        get: {
                            MarketEtfFetcher.EtfCategory.allCases.firstIndex(of: currentTab) ?? 0
                        },
                        set: { index in
                            currentTab = MarketEtfFetcher.EtfCategory.allCases[index]
                        }
                    )
                )

                MarketEtfView(category: currentTab, factory: viewModelFactory)
                    .id(currentTab)
                    .frame(maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
