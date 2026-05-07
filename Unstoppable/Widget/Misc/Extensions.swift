import SwiftUI

extension Coin {
    var image: Image? {
        do {
            let iconUrl = "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@3x.png"
            return try image(url: iconUrl)
        } catch {
            guard let alternativeUrl = imageUrl else { return nil }
            return try? image(url: alternativeUrl)
        }
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

    private func image(url: String) throws -> Image? {
        guard let url = URL(string: url) else { return nil }
        let data = try Data(contentsOf: url)

        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    private func priceChange(timePeriod: WatchlistTimePeriod) -> Decimal? {
        switch timePeriod {
        case .hour24: return priceChange24h
        case .day1: return priceChange1d
        case .week1: return priceChange1w
        case .month1: return priceChange1m
        case .month3: return priceChange3m
        }
    }
}
