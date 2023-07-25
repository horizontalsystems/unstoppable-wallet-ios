import UIKit
import UIExtensions
import Chart

class ChartIndicatorFactory {
    static let precalculatedColor = [UIColor.themeYellowD]
    static let maColors = [UIColor(hex: 0xF54900), UIColor(hex: 0xBF5AF2), UIColor(hex: 0x09C1AB)]
    static let maPeriods = [9, 25, 50]
    static let rsiPeriod = 12
    static let macdPeriod = [12, 26, 9]

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

    static func defaultIndicators(subscribed: Bool) -> [ChartIndicator] {
        var indicators = [ChartIndicator]()
        let maEnabledArray = [true, true, subscribed]
        let maIndicators = maPeriods.enumerated().map { index, period in
            MaIndicator(
                    id: "MA",
                    index: index,
                    enabled: maEnabledArray[index],
                    period: period,
                    type: .ema,
                    configuration: maConfiguration(index))
        }
        indicators.append(contentsOf: maIndicators)
        indicators.append(contentsOf: [
            RsiIndicator(
                    id: ChartIndicator.AbstractType.rsi.rawValue,
                    index: 0,
                    enabled: subscribed,
                    period: rsiPeriod,
                    configuration: rsiConfiguration),
            MacdIndicator(
                    id: ChartIndicator.AbstractType.macd.rawValue,
                    index: 0,
                    enabled: false,
                    fast: macdPeriod[0],
                    slow: macdPeriod[1],
                    signal: macdPeriod[2],
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
