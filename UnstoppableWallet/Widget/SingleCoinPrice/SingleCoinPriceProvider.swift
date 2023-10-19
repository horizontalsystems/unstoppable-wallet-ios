import Foundation
import SwiftUI
import WidgetKit

struct SingleCoinPriceProvider: IntentTimelineProvider {
    private let fallbackCoinUid = "bitcoin"

    func placeholder(in _: Context) -> SingleCoinPriceEntry {
        SingleCoinPriceEntry(
            date: Date(),
            coinUid: fallbackCoinUid,
            coinIcon: nil,
            coinCode: "BTC",
            price: "$30000",
            priceChange: "2.45",
            priceChangeType: .unknown,
            chartPoints: placeholderChartPoints()
        )
    }

    func getSnapshot(for _: SingleCoinPriceIntent, in _: Context, completion: @escaping (SingleCoinPriceEntry) -> Void) {
        Task {
            let entry = try await fetch(coinUid: fallbackCoinUid)
            completion(entry)
        }
    }

    func getTimeline(for configuration: SingleCoinPriceIntent, in _: Context, completion: @escaping (Timeline<SingleCoinPriceEntry>) -> Void) {
        let coinUid = configuration.selectedCoin?.identifier ?? fallbackCoinUid

        Task {
            let entry = try await fetch(coinUid: coinUid)

            if let nextUpdate = Calendar.current.date(byAdding: DateComponents(minute: 15), to: Date()) {
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }

    private func fetch(coinUid: String) async throws -> SingleCoinPriceEntry {
        let currency = CurrencyManager(storage: SharedLocalStorage()).baseCurrency
        let apiProvider = ApiProvider(baseUrl: "https://api-dev.blocksdecoded.com")

        let coin = try await apiProvider.coinWithPrice(uid: coinUid, currencyCode: currency.code)

        let iconUrl = "https://cdn.blocksdecoded.com/coin-icons/32px/\(coin.uid)@3x.png"
        let coinIcon = URL(string: iconUrl).flatMap { try? Data(contentsOf: $0) }.flatMap { UIImage(data: $0) }.map { Image(uiImage: $0) }

        var chartPoints: [SingleCoinPriceEntry.ChartPoint]?

        if let points = try? await apiProvider.coinPriceChart(coinUid: coinUid, currencyCode: currency.code) {
            chartPoints = points
                .sorted { point, point2 in
                    point.timestamp < point2.timestamp
                }
                .map { point in
                    SingleCoinPriceEntry.ChartPoint(
                        date: Date(timeIntervalSince1970: TimeInterval(point.timestamp)),
                        value: point.price
                    )
                }
        }

        return SingleCoinPriceEntry(
            date: Date(),
            coinUid: coin.uid,
            coinIcon: coinIcon,
            coinCode: coin.code,
            price: coin.price.flatMap { ValueFormatter.format(currency: currency, value: $0) } ?? "n/a",
            priceChange: coin.priceChange24h.flatMap { ValueFormatter.format(percentValue: $0) } ?? "n/a",
            priceChangeType: coin.priceChange24h.map { $0 >= 0 ? .up : .down } ?? .unknown,
            chartPoints: chartPoints
        )
    }

    private func placeholderChartPoints() -> [SingleCoinPriceEntry.ChartPoint] {
        var points = [SingleCoinPriceEntry.ChartPoint]()

        for i in 0 ..< 8 {
            let baseTimeStamp = TimeInterval(i) * 100
            let baseValue = Decimal(i) * 2

            points.append(contentsOf: [
                SingleCoinPriceEntry.ChartPoint(date: Date(timeIntervalSince1970: baseTimeStamp), value: baseValue + 2),
                SingleCoinPriceEntry.ChartPoint(date: Date(timeIntervalSince1970: baseTimeStamp + 25), value: baseValue + 6),
                SingleCoinPriceEntry.ChartPoint(date: Date(timeIntervalSince1970: baseTimeStamp + 50), value: baseValue),
                SingleCoinPriceEntry.ChartPoint(date: Date(timeIntervalSince1970: baseTimeStamp + 75), value: baseValue + 9),
            ])
        }

        points.append(SingleCoinPriceEntry.ChartPoint(date: Date(timeIntervalSince1970: 800), value: 16))

        return points
    }
}
