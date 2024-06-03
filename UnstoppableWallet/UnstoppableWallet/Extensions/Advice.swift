import MarketKit

extension TechnicalAdvice.Advice: Identifiable {
    public var id: Self {
        self
    }

    var shortTitle: String {
        switch self {
        case .oversold, .overbought: return "market.signal.risky".localized
        case .strongBuy: return "market.signal.strong_buy".localized
        case .buy: return "market.signal.buy".localized
        case .neutral: return "market.signal.neutral".localized
        case .sell: return "market.signal.sell".localized
        case .strongSell: return "market.signal.strong_sell".localized
        }
    }
}
