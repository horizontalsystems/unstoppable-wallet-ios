import Combine
import Foundation
import Chart
import CurrencyKit
import HsExtensions
import MarketKit

class TechnicalIndicatorService {
    static let maPeriods: [Int] = [9, 25, 50, 100, 200]

    // sometimes backend can return points with gaps (5-15 point) but we need calculating all indicators
    private static let additionalPoints = 20
    private static let pointCount = 200

    private var tasks = Set<AnyTask>()

    private let coinUid: String
    private let currencyKit: CurrencyKit.Kit
    private let marketKit: MarketKit.Kit

    let allPeriods: [HsPointTimePeriod] = [.hour1, .hour4, .day1, .week1]
    var period: HsPointTimePeriod = .day1 {
        didSet {
            fetch()
        }
    }

    @PostPublished private(set) var state: DataStatus<[SectionItem]> = .loading

    init(coinUid: String, currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit) {
        self.coinUid = coinUid
        self.currencyKit = currencyKit
        self.marketKit = marketKit

        fetch()
    }

    func fetch() {
        let currency = currencyKit.baseCurrency

        tasks.forEach { task in task.cancel() }
        tasks = Set()

        state = .loading
        Task { [weak self, marketKit, coinUid, currency, period] in
            do {
                let points = try await marketKit.chartPoints(
                        coinUid: coinUid,
                        currencyCode: currency.code,
                        interval: period,
                        pointCount: Self.pointCount + Self.additionalPoints
                )

                self?.handle(chartPoints: points, period: period)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

    private func cross(_ value1: Decimal, _ value2: Decimal) -> Advice {
        if value1 > value2 {
            return .buy
        } else if value1 < value2 {
            return .sell
        } else {
            return .neutral
        }
    }

    private func handle(chartPoints: [ChartPoint], period: HsPointTimePeriod) {
        do {
            var sectionItems = [SectionItem]()
            let chartData = try calculateIndicators(chartPoints: chartPoints)

            guard let lastRate = chartData.last(name: ChartData.rate) else {
                throw IndicatorCalculator.IndicatorError.notEnoughData
            }

            var maItems = [Item]()

            // Calculate ma advices
            let types: [String] = ["ema", "sma"]
            for type in types {
                for period in Self.maPeriods {
                    let advice: Advice
                    if let maValue = chartData.last(name: "\(type)_\(period)") {
                        advice = cross(lastRate, maValue)
                    } else {
                        advice = .noData
                    }
                    maItems.append(Item(name: "\(type.uppercased()) \(period)", advice: advice))
                }
            }

            // Calculate cross advices
            let crossAdvice: Advice
            if let ema25 = chartData.last(name: "ema_25"),
               let ema50 = chartData.last(name: "ema_50") {
                crossAdvice = cross(ema25, ema50)
            } else {
                crossAdvice = .noData
            }
            maItems.append(Item(name: "EMA Cross 25,50", advice: crossAdvice))
            sectionItems.append(SectionItem(name: ChartIndicator.Category.movingAverage.title, items: maItems))

            var oscillatorItems = [Item]()

            // Calculate oscillators
            let rsiAdvice: Advice
            if let rsi = chartData.last(name: "rsi") {
                if rsi > 70 {
                    rsiAdvice = .sell   // overbought
                } else if rsi < 30 {
                    rsiAdvice = .buy   // oversold
                } else {
                    rsiAdvice = .neutral
                }
            } else {
                rsiAdvice = .noData
            }
            oscillatorItems.append(Item(name: "RSI", advice: rsiAdvice))

            // Calculate MACD
            let macdAdvice: Advice
            if let macdMacd = chartData.last(name: "macd_macd"),
               let macdSignal = chartData.last(name: "macd_signal") {
                macdAdvice = cross(macdSignal, macdMacd)
            } else {
                macdAdvice = .noData
            }
            oscillatorItems.append(Item(name: "MACD", advice: macdAdvice))
            sectionItems.append(SectionItem(name: ChartIndicator.Category.oscillator.title, items: oscillatorItems))
            state = .completed(sectionItems)
        } catch {
            state = .failed(error)
        }
    }

    private func calculateIndicators(chartPoints: [ChartPoint]) throws -> ChartData {
        guard let startTimestamp = chartPoints.first?.timestamp, let endTimestamp = chartPoints.last?.timestamp else {
            throw IndicatorCalculator.IndicatorError.notEnoughData
        }

        let values = chartPoints.map { $0.value }

        var items = [ChartItem]()
        for point in chartPoints {
            let chartItem = ChartItem(timestamp: point.timestamp)
            chartItem.added(name: ChartData.rate, value: point.value)
            items.append(chartItem)
        }

        let chartData = ChartData(items: items, startWindow: startTimestamp, endWindow: endTimestamp)

        for period in Self.maPeriods {
            if let emaValues = try? IndicatorCalculator.ema(period: period, values: values) {
                chartData.add(name: "ema_\(period)", values: emaValues)
            }
            if let smaValues = try? IndicatorCalculator.ma(period: period, values: values) {
                chartData.add(name: "sma_\(period)", values: smaValues)
            }
        }

        if let rsiValues = try? IndicatorCalculator.rsi(period: ChartIndicatorFactory.rsiPeriod, values: values) {
            chartData.add(name: "rsi", values: rsiValues)
        }
        if let macdData = try? IndicatorCalculator.macd(
                fast: ChartIndicatorFactory.macdPeriod[0],
                long: ChartIndicatorFactory.macdPeriod[1],
                signal: ChartIndicatorFactory.macdPeriod[2],
                values: values) {

            chartData.add(name: "macd_macd", values: macdData.macd)
            chartData.add(name: "macd_signal", values: macdData.signal)
            chartData.add(name: "macd_histogram", values: macdData.histogram)
        }

        return chartData
    }

}

extension TechnicalIndicatorService {

    enum Advice {
        case noData
        case buy
        case sell
        case neutral

        var rating: Int {
            switch self {
            case .noData, .neutral: return 0
            case .buy: return 1
            case .sell: return -1
            }
        }
    }

    struct Item {
        let name: String
        let advice: Advice
    }

    struct SectionItem {
        let name: String
        let items: [Item]
    }

    struct Indicator {
        let category: ChartIndicator.Category
        let indicatorName: String
    }

}
