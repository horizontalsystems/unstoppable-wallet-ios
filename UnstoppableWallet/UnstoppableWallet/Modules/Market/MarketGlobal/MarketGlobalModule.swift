import UIKit
import RxSwift
import Chart
import LanguageKit

struct MarketGlobalModule {

    enum MetricsType {
        case totalMarketCap, volume24h, defiCap, tvlInDefi

        var title: String {
            switch self {
            case .totalMarketCap: return "market.global.total_market_cap.title".localized
            case .volume24h: return "market.global.volume_24h.title".localized
            case .defiCap: return "market.global.defi_cap.title".localized
            case .tvlInDefi: return "market.global.tvl_in_defi.title".localized
            }
        }

        var description: String {
            switch self {
            case .totalMarketCap: return "market.global.btc_dominance.description".localized
            case .volume24h: return "market.global.volume_24h.description".localized
            case .defiCap: return "market.global.defi_cap.description".localized
            case .tvlInDefi: return "market.global.tvl_in_defi.description".localized
            }
        }

        var marketField: MarketModule.MarketField {
            switch self {
            case .totalMarketCap: return .marketCap
            case .volume24h: return .volume
            case .defiCap: return .marketCap
            case .tvlInDefi: return .price
            }
        }

    }

}
