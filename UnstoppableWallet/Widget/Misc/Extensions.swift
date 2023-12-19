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

    var formattedPriceChange: String {
        priceChange24h.flatMap { ValueFormatter.format(percentValue: $0) } ?? "n/a"
    }

    var priceChangeType: PriceChangeType {
        guard let priceChange24h else {
            return .unknown
        }

        return priceChange24h >= 0 ? .up : .down
    }
}
