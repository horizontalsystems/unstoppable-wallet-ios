import Foundation
import MarketKit
import UIKit

extension Etf {
    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/etf-tresuries/\(ticker)@\(scale)x.png"
    }

    func inflow(timePeriod: MarketEtfViewModel.TimePeriod) -> Decimal? {
        switch timePeriod {
        case let .period(timePeriod): return inflows[timePeriod]
        case .all: return totalInflow
        }
    }
}

struct RankedEtf: Hashable {
    let etf: Etf
    let rank: Int

    public static func == (lhs: RankedEtf, rhs: RankedEtf) -> Bool {
        lhs.etf.ticker == rhs.etf.ticker
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(etf.ticker)
    }
}

extension [RankedEtf] {
    func sorted(sortBy: MarketEtfViewModel.SortBy, timePeriod: MarketEtfViewModel.TimePeriod) -> [RankedEtf] {
        sorted { lhsRankedEtf, rhsRankedEtf in
            let lhsEtf = lhsRankedEtf.etf
            let rhsEtf = rhsRankedEtf.etf

            switch sortBy {
            case .highestAssets, .lowestAssets:
                guard let lhsAssets = lhsEtf.totalAssets else {
                    return false
                }
                guard let rhsAssets = rhsEtf.totalAssets else {
                    return true
                }

                return sortBy == .highestAssets ? lhsAssets > rhsAssets : lhsAssets < rhsAssets
            case .inflow, .outflow:
                guard let lhsInflow = lhsEtf.inflow(timePeriod: timePeriod) else {
                    return false
                }
                guard let rhsInflow = rhsEtf.inflow(timePeriod: timePeriod) else {
                    return true
                }

                return sortBy == .inflow ? lhsInflow > rhsInflow : lhsInflow < rhsInflow
            }
        }
    }
}
