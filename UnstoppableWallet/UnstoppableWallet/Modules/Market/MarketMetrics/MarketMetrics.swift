import Foundation

struct MetricData {
    let value: String
    let diff: Decimal
}

struct MarketMetrics {
    let totalMarketCap: MetricData
    let volume24h: MetricData
    let btcDominance: MetricData
    let defiCap: MetricData
    let defiTvl: MetricData
}
