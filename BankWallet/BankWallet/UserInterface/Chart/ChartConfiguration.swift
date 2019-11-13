import UIKit

class ChartConfiguration {
    var showGrid: Bool = true

    var animationDuration: TimeInterval = 0.3

    var backgroundColor: UIColor = .clear

    var chartInsets: UIEdgeInsets = .zero
    var curveWidth: CGFloat = 1
    var curvePositiveColor: UIColor = .cryptoGreen
    var curveNegativeColor: UIColor = .cryptoRed
    var curveIncompleteColor: UIColor = .appGray50

    var curveVerticalOffset: Decimal = 0.05

    var gradientPositiveColor: UIColor = .cryptoGreen
    var gradientNegativeColor: UIColor = .cryptoRed
    var gradientIncompleteColor: UIColor = .appGray50
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
    var selectedIndicatorColor: UIColor = .crypto_Bars_Dark
    var selectedCurveColor: UIColor = .crypto_Bars_Dark
    var selectedGradientColor: UIColor = .crypto_Bars_Dark
}
