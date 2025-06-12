import Kingfisher
import MarketKit
import SwiftUI

struct CoinIconView: View {
    let coin: Coin?
    let placeholderImage: String?

    init(coin: Coin?, placeholderImage: String? = nil) {
        self.coin = coin
        self.placeholderImage = placeholderImage
    }

    var body: some View {
        IconView(url: coin?.imageUrl, alternativeUrl: coin?.image, placeholderImage: placeholderImage, type: .circle)
    }
}

struct IconView: View {
    let url: String?
    let alternativeUrl: String?
    let placeholderImage: String?
    let type: IconType
    let size: CGFloat

    init(url: String?, alternativeUrl: String? = nil, placeholderImage: String? = nil, type: IconType = .circle, size: CGFloat = .iconSize32) {
        self.url = url
        self.alternativeUrl = alternativeUrl
        self.placeholderImage = placeholderImage
        self.type = type
        self.size = size
    }

    var body: some View {
        if let alternativeUrl, let alternativeURL = URL(string: alternativeUrl) {
            if ImageCache.default.isCached(forKey: alternativeUrl) {
                icon(url: alternativeURL)
                    .clipShape(type)
                    .frame(width: size, height: size)
            } else {
                icon(url: url.flatMap { URL(string: $0) }).alternativeSources([.network(alternativeURL)])
                    .clipShape(type)
                    .frame(width: size, height: size)
            }
        } else {
            icon(url: url.flatMap { URL(string: $0) })
                .clipShape(type)
                .frame(width: size, height: size)
        }
    }

    @ViewBuilder func icon(url: URL?) -> some KFImageProtocol {
        KFImage.url(url)
            .resizable()
            .placeholder {
                if let placeholderImage, UIImage(named: placeholderImage) != nil {
                    Image(placeholderImage)
                        .resizable()
                        .frame(width: size, height: size)
                } else {
                    type
                        .fill(Color.themeBlade)
                        .frame(width: size, height: size)
                }
            }
    }

    enum IconType: Shape {
        case circle
        case squircle

        func path(in rect: CGRect) -> Path {
            switch self {
            case .circle:
                return Circle().path(in: rect)
            case .squircle:
                return RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous).path(in: rect)
            }
        }
    }
}
