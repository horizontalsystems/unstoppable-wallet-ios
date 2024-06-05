import SwiftUI

extension Coin {
    var image: Image? {
        let iconUrl = "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@3x.png"

        guard let url = URL(string: iconUrl) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let uiImage = UIImage(data: data) else { return nil }

        return Image(uiImage: uiImage)
    }

    func formattedPrice(currency: Currency) -> String {
        price.flatMap { ValueFormatter.format(currency: currency, value: $0) } ?? "n/a"
    }

    func formattedPriceChange(timePeriod: WatchlistTimePeriod = .day1) -> String {
        priceChange(timePeriod: timePeriod).flatMap { ValueFormatter.format(percentValue: $0) } ?? "n/a"
    }

    func priceChangeType(timePeriod: WatchlistTimePeriod = .day1) -> PriceChangeType {
        guard let priceChange = priceChange(timePeriod: timePeriod) else {
            return .unknown
        }

        return priceChange >= 0 ? .up : .down
    }

    private func priceChange(timePeriod: WatchlistTimePeriod) -> Decimal? {
        switch timePeriod {
        case .day1: return priceChange1d
        case .week1: return priceChange1w
        case .month1: return priceChange1m
        case .month3: return priceChange3m
        }
    }
}
