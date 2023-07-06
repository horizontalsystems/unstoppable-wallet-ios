import UIKit
import UIExtensions
import Chart

class ChartIndicatorFactory {
    static let precalculatedColor = [UIColor.themeYellowD]
    static let maColors = [UIColor(hex: 0xF54900), UIColor(hex: 0xBF5AF2), UIColor(hex: 0x09C1AB)]
    static let maPeriods = [9, 25, 50]

    static func maConfiguration(_ index: Int) -> ChartIndicator.LineConfiguration {
        let index = index % maColors.count
        return .init(color: color(maColors[index]), width: 1)
    }

    static let rsiConfiguration = ChartIndicator.LineConfiguration(
            color: color(.themeYellowD),
            width: 1
    )
    static let macdConfiguration = MacdIndicator.Configuration(
            fastColor: color(UIColor(hex: 0x3372FF)),
            longColor: color(.themeYellowD),
            positiveColor: color(.themeGreenD),
            negativeColor: color(.themeRedD),
            width: 2,
            signalWidth: 1
    )

    private static func color(_ color: UIColor, alpha: CGFloat = 0.5) -> ChartColor {
        ChartColor(color.withAlphaComponent(alpha))
    }

    static var `default`: [ChartIndicator] {
        var indicators = [ChartIndicator]()
        let maIndicators = maPeriods.enumerated().map { index, period in
            MaIndicator(
                    id: MaIndicator.MaType.ema.rawValue,
                    index: index,
                    enabled: true,
                    period: period,
                    type: .ema,
                    configuration: maConfiguration(index))
        }
        indicators.append(contentsOf: maIndicators)
        indicators.append(contentsOf: [
            RsiIndicator(
                    id: ChartIndicator.AbstractType.rsi.rawValue,
                    index: 0,
                    enabled: true,
                    period: 12,
                    configuration: rsiConfiguration),
            MacdIndicator(
                    id: ChartIndicator.AbstractType.macd.rawValue,
                    index: 0,
                    enabled: false,
                    fast: 12,
                    long: 26,
                    signal: 9,
                    configuration: macdConfiguration
            )
        ])

        return indicators
    }

}

extension ChartIndicatorFactory {

    struct MacdColor {
        let fast: UIColor
        let slow: UIColor
        let positive: UIColor
        let negative: UIColor
    }

}