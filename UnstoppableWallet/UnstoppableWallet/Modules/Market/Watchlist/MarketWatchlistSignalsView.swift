import MarketKit
import SwiftUI

struct MarketWatchlistSignalsView: View {
    @ObservedObject var viewModel: MarketWatchlistViewModel
    @Binding var isPresented: Bool

    @State private var maxBadgeWidth: CGFloat = .zero
    @State private var doNotShowAgain = false

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin16) {
                            Text("market.watchlist.signals.description".localized)
                                .themeSubhead2()
                                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin8, trailing: .margin16))

                            ListSection {
                                row(signal: .strongBuy)
                                row(signal: .buy)
                                row(signal: .neutral)
                                row(signal: .sell)
                                row(signal: .strongSell)
                                row(signal: .overbought)
                            }
                            .themeListStyle(.bordered)
                            .onPreferenceChange(MaxWidthPreferenceKey.self) {
                                maxBadgeWidth = $0
                            }

                            HighlightedTextView(text: "market.watchlist.signals.warning".localized, style: .warning)

                            ListSection {
                                ClickableRow(action: {
                                    doNotShowAgain.toggle()
                                }) {
                                    if doNotShowAgain {
                                        ZStack {
                                            Circle().fill(Color.themeJacob)
                                            Image("check_2_24").themeIcon(color: .themeDark)
                                        }
                                        .frame(width: .iconSize24, height: .iconSize24)
                                    } else {
                                        Circle()
                                            .fill(Color.themeSteel20)
                                            .frame(width: .iconSize24, height: .iconSize24)
                                    }

                                    Text("market.watchlist.signals.dont_show_again".localized).themeSubhead2(color: .themeLeah)
                                }
                            }
                            .themeListStyle(.lawrence)
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                } bottomContent: {
                    Button(action: {
                        viewModel.showSignals = true

                        if doNotShowAgain {
                            viewModel.signalsApproved = true
                        }

                        isPresented = false
                    }) {
                        Text("market.watchlist.signals.turn_on".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                }
            }
            .navigationTitle("market.watchlist.signals".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder private func row(signal: TechnicalAdvice.Advice) -> some View {
        ListRow {
            MarketWatchlistSignalBadge(signal: signal)
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(key: MaxWidthPreferenceKey.self, value: geometry.size.width)
                    }
                    .scaledToFill()
                )
                .frame(width: maxBadgeWidth)

            Text(description(signal: signal)).themeSubhead2(color: .themeLeah)
        }
    }

    private func description(signal: TechnicalAdvice.Advice) -> String {
        switch signal {
        case .neutral: return "market.watchlist.signals.neutral.description".localized
        case .buy: return "market.watchlist.signals.buy.description".localized
        case .sell: return "market.watchlist.signals.sell.description".localized
        case .strongBuy: return "market.watchlist.signals.strong_buy.description".localized
        case .strongSell: return "market.watchlist.signals.strong_sell.description".localized
        case .overbought, .oversold: return "market.watchlist.signals.risky.description".localized
        }
    }

    private struct MaxWidthPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = .zero

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            let nextValue = nextValue()
            guard nextValue > value else { return }
            value = nextValue
        }
    }
}
