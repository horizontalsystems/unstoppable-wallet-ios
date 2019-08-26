import UIKit

enum ChartType: String, CaseIterable {
    case day = "DAILY"
    case week = "WEEKLY"
    case month = "MONTHLY"
    case halfYear = "MONTHLY6"
    case year = "MONTHLY18"

    var tag: Int {
        switch self {
        case .day: return 1
        case .week: return 2
        case .month: return 3
        case .halfYear: return 4
        case .year: return 5
        }
    }

    var title: String {
        switch self {
        case .day: return "chart.time_duration.day".localized
        case .week: return "chart.time_duration.week".localized
        case .month: return "chart.time_duration.month".localized
        case .halfYear: return "chart.time_duration.halyear".localized
        case .year: return "chart.time_duration.year".localized
        }
    }

}

class ChartConfiguration {
    var showGrid: Bool = true

    var animationDuration: TimeInterval = 0.3

    var backgroundColor: UIColor = .clear

    var curveWidth: CGFloat = 1
    var curvePositiveColor: UIColor = .cryptoGreen
    var curveNegativeColor: UIColor = .cryptoRed

    var curveVerticalOffset: Decimal = 0.05

    var gradientPositiveColor: UIColor = .cryptoGreen
    var gradientNegativeColor: UIColor = .cryptoRed
    var gradientStartTransparency: CGFloat = 0.8
    var gradientFinishTransparency: CGFloat = 0.05

    var gridNonVisibleLineDeltaX: CGFloat = 5                           // if timestamp line drawing near sides lines we must draw only sides line
    var gridHorizontalLineCount: Int = 5
    var gridMaxScale: Int = 4

    var gridColor: UIColor = .cryptoSteel20
    var gridTextColor: UIColor = .cryptoGray
    var gridTextFont: UIFont = .systemFont(ofSize: 12)

    var gridTextMargin: CGFloat = 4
    var gridTextRightMargin: CGFloat = 16

    var selectedCircleRadius: CGFloat = 5.5
    var selectedIndicatorColor: UIColor = .white
    var selectedCurveColor: UIColor = .white
    var selectedGradientColor: UIColor = .white

    init() {
        selectedIndicatorColor = .crypto_Bars_Dark
        selectedCurveColor = .crypto_Bars_Dark
        selectedGradientColor = .crypto_Bars_Dark
    }

}
