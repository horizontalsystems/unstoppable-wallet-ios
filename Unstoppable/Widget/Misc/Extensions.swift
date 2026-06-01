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

extension CGFloat {
    static let heightOnePixel: CGFloat = 1 / UIScreen.main.scale
}

extension Color {
    static let themeLeah = Color("Leah")
    static let themeGray = Color("Gray")
    static let themeBlade = Color("Blade")
    static let themeRemus = Color("Remus")
    static let themeLucian = Color("Lucian")
}

extension Font {
    static func manRopeFont(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
        case .regular: return Font.custom("Manrope-Regular", size: size)
        case .medium: return Font.custom("Manrope-Medium", size: size)
        case .semibold: return Font.custom("Manrope-SemiBold", size: size)
        default: fatalError("Can't provide other weight for Manrope!")
        }
    }

    // static let themeTitle1: Font = .manRopeFont(size: 38, weight: .semibold)
    // static let themeTitle2: Font = .manRopeFont(size: 36, weight: .medium)
    // static let themeTitle2R: Font = .manRopeFont(size: 32, weight: .regular)
    // static let themeTitle3: Font = .manRopeFont(size: 24, weight: .semibold)
    static let themeHeadline1: Font = .manRopeFont(size: 20, weight: .semibold)
    // static let themeHeadline2: Font = .manRopeFont(size: 16, weight: .semibold)
    // static let themeBody: Font = .manRopeFont(size: 16, weight: .medium)
    static let themeSubhead1: Font = .manRopeFont(size: 14, weight: .medium)
    // static let themeSubhead1I: Font = .manRopeFont(size: 14, weight: .medium).italic()
    static let themeSubhead2: Font = .manRopeFont(size: 14, weight: .regular)
    static let themeCaption: Font = .manRopeFont(size: 12, weight: .regular)
    // static let themeCaptionSB: Font = .manRopeFont(size: 12, weight: .semibold)
    // static let themeMicro: Font = .manRopeFont(size: 10, weight: .regular)
    static let themeMicroSB: Font = .manRopeFont(size: 10, weight: .semibold)
}
