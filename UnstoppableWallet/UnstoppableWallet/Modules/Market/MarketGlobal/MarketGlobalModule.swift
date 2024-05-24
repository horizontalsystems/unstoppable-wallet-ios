import Chart
import RxSwift
import UIKit

enum MarketGlobalModule {
    static let dominance = "dominance"
    static let totalAssets = "total_assets"
    static let totalInflow = "total_inflow"

    enum MetricsType: Identifiable {
        case totalMarketCap, volume24h, defiCap, tvlInDefi

        var id: Self {
            self
        }

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
            case .totalMarketCap: return "market.global.total_market_cap.description".localized
            case .volume24h: return "market.global.volume_24h.description".localized
            case .defiCap: return "market.global.defi_cap.description".localized
            case .tvlInDefi: return "market.global.tvl_in_defi.description".localized
            }
        }

        var imageUid: String {
            switch self {
            case .totalMarketCap: return "total_mcap"
            case .volume24h: return "total_volume"
            case .defiCap: return "defi_cap"
            case .tvlInDefi: return "tvl"
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
