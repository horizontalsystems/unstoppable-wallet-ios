import MarketKit
import SwiftUI

struct MarketWatchlistSignalsView: View {
    var setShowSignals: (Bool) -> Void
    @Binding var isPresented: Bool

    @State private var maxBadgeWidth: CGFloat = .zero

    var body: some View {
        ThemeNavigationStack {
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
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                } bottomContent: {
                    Button(action: {
                        setShowSignals(true)
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
            BadgeViewNew(signal.title, mode: .transparent, colorStyle: signal.colorStyle)
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
