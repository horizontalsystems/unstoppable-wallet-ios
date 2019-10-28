import Foundation

struct ChartData {
    var coinCode: CoinCode
    var marketCap: Decimal?
    var stats: [ChartTypeOld: [ChartPoint]]
    var diffs: [ChartTypeOld: Decimal]
}
