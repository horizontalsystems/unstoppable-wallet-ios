import MarketKit
import SwiftUI

struct MarketWatchlistSignalBadge: View {
    let signal: TechnicalAdvice.Advice

    var body: some View {
        Text(signal.searchTitle)
            .font(.themeMicroSB)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, .margin6)
            .padding(.vertical, .margin2)
            .background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(backgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
    }

    private var foregroundColor: Color {
        switch signal {
        case .neutral: return .themeBran
        case .buy: return .themeRemus
        case .sell: return .themeLucian
        case .strongBuy, .strongSell: return .themeTyler
        case .overbought, .oversold: return .themeJacob
        }
    }

    private var backgroundColor: Color {
        switch signal {
        case .neutral: return .themeSteel20
        case .buy: return .themeGreen.opacity(0.2)
        case .sell: return .themeRed.opacity(0.2)
        case .strongBuy: return .themeRemus
        case .strongSell: return .themeLucian
        case .overbought, .oversold: return .themeYellow20
        }
    }
}
