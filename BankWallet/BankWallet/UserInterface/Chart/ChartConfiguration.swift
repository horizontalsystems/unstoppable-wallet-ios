import UIKit

enum ChartType {
    case day
    case week
    case month
    case halfYear
    case year
}

class ChartConfiguration {
    var chartType: ChartType = .week
    var showGrid: Bool = true

    var animated: Bool = true
    var animationDuration: TimeInterval = 0.5

    var backgroundColor: UIColor = .clear

    var curveWidth: CGFloat = 1
    var curveColor: UIColor = .cryptoGreen

    var curveVerticalOffset: Decimal = 0.05

    var gradientColor: UIColor = .cryptoGreen
    var gradientStartTransparency: CGFloat = 0.8
    var gradientFinishTransparency: CGFloat = 0.05

    var gridNonVisibleLineDeltaX: CGFloat = 5                           // if timestamp line drawing near sides lines we must draw only sides line
    var gridHorizontalLineCount: Int = 5
    var gridMaxScale: Int = 4

    var gridColor: UIColor = UIColor.lightGray.withAlphaComponent(0.5)
    var gridTextColor: UIColor = UIColor.lightGray
    var gridTextFont: UIFont = .systemFont(ofSize: 12)

    var gridTextMargin: CGFloat = 4
    var gridTextRightMargin: CGFloat = 16

    var selectedCircleRadius: CGFloat = 5.5
    var selectedIndicatorColor: UIColor = .white
    var selectedCurveColor: UIColor = .white
    var selectedGradientColor: UIColor = .white

    init(growing: Bool) {
        let chartColor = growing ? UIColor.cryptoGreen : UIColor.cryptoRed

        curveColor = chartColor
        gradientColor = chartColor

        selectedIndicatorColor = .crypto_Bars_Dark
        selectedCurveColor = .crypto_Bars_Dark
        selectedGradientColor = .crypto_Bars_Dark
    }

}
