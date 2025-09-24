import Kingfisher
import MarketKit
import SwiftUI

struct BalanceCoinIconView: View {
    let coin: Coin
    let state: AdapterState
    let isReachable: Bool
    let placeholderImage: String?
    let onTapFailed: () -> Void

    var body: some View {
        Group {
            if !isReachable {
                // show standard icon when noInternet
                coinIconView()
            } else {
                switch state {
                case .notSynced:
                    ZStack {
                        Circle().fill(Color.themeBlade)
                        Image("warning_filled").themeIcon(color: .themeLucian)
                    }
                    .frame(size: .iconSize32)
                    .onTapGesture(perform: onTapFailed)
                default:
                    coinIconView()
                }
            }
        }
    }

    @ViewBuilder
    private func coinIconView() -> some View {
        CoinIconView(coin: coin, placeholderImage: placeholderImage)
            .opacity(state.syncing ? 0.5 : 1)
            .overlay {
                switch state {
                case .connecting:
                    ProgressView(value: 0.1)
                        .progressViewStyle(DeterminiteSpinnerStyle())
                        .frame(width: 36, height: 36)
                        .spinning()
                case let .syncing(progress, _), let .customSyncing(_, _, progress):
                    ProgressView(value: max(0.1, Float(progress ?? 10) / 100))
                        .progressViewStyle(DeterminiteSpinnerStyle())
                        .frame(width: 36, height: 36)
                        .spinning()
                default:
                    EmptyView()
                }
            }
    }
}

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
