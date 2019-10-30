import XRatesKit

class GridIntervalConverter {

    static func convert(chartType: ChartType) -> GridIntervalType {
         switch chartType {
         case .day: return .hour(6)
         case .week: return .day(2)
         case .month: return .day(6)
         case .halfYear: return .month(1)
         case .year: return .month(2)
        }
    }

}
