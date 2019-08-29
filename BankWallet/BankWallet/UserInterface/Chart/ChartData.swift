import Foundation

struct ChartData {
    var marketCap: Decimal?
    var stats: [ChartType: [ChartPoint]]
    var diffs: [ChartType: Decimal]
}
