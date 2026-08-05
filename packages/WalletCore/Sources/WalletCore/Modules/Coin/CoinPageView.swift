import MarketKit
import SwiftUI

struct CoinPageView: View {
    @StateObject private var viewModel: CoinPageViewModel

    @StateObject private var overviewViewModel: CoinOverviewViewModel
    @StateObject private var chartViewModel: CoinChartViewModel

    @Environment(\.dismiss) private var dismiss

    init(coin: Coin) {
        _viewModel = StateObject(wrappedValue: CoinPageViewModel(coin: coin))
        _overviewViewModel = StateObject(wrappedValue: CoinOverviewViewModel(coinUid: coin.uid))
        _chartViewModel = StateObject(wrappedValue: CoinChartViewModel.instance(coinUid: coin.uid))
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                if let token = viewModel.swapToken {
                    BottomGradientWrapper {
                        overview()
                    } bottomContent: {
                        HStack(spacing: .margin8) {
                            Button(action: {
                                Coordinator.shared.present { _ in
                                    RegularMultiSwapView(tokenOut: token)
                                }
                            }) {
                                Text("coin_page.buy".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .yellow))

                            Button(action: {
                                Coordinator.shared.present { _ in
                                    RegularMultiSwapView(token: token)
                                }
                            }) {
                                Text("coin_page.sell".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .gray))
                        }
                    }
                } else {
                    overview()
                }
            }
            .navigationTitle(viewModel.coin.code)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("close")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.isFavorite.toggle()
                    }) {
                        Image("heart")
                    }
                    .modifier(ConfirmationButtonStyle(isActive: viewModel.isFavorite))
                }
            }
        }
    }

    @ViewBuilder private func overview() -> some View {
        CoinOverviewView(viewModel: overviewViewModel, chartViewModel: chartViewModel)
            .frame(maxHeight: .infinity)
            .onFirstAppear {
                overviewViewModel.load()
            }
    }
}
