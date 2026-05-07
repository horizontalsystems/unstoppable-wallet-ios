enum MarketGlobalModule {
    static let dominance = "dominance"
    static let totalAssets = "total_assets"
    static let totalInflow = "total_inflow"
    static let dailyInflow = "daily_inflow"

    enum MetricsType: Identifiable {
        case totalMarketCap, volume24h, defiCap, tvlInDefi

        var id: Self {
            self
        }
    }
}
