import Kingfisher
import MarketKit
import SwiftUI

struct BalanceCoinIconView: View {
    let token: Token
    let state: AdapterState
    let isReachable: Bool
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
                    .frame(size: 40)
                    .onTapGesture(perform: onTapFailed)
                default:
                    coinIconView()
                }
            }
        }
    }

    @ViewBuilder
    private func coinIconView() -> some View {
        CoinIconView(token: token, iconOpacity: state.syncing ? 0.5 : 1, iconOverlay: syncOverlay)
    }

    private var syncOverlay: AnyView? {
        switch state {
        case .connecting:
            return AnyView(
                ProgressView(value: 0.1)
                    .progressViewStyle(DeterminiteSpinnerStyle())
                    .frame(width: 44, height: 44)
                    .spinning()
            )
        case let .syncing(progress, _, _), let .customSyncing(_, _, progress):
            return AnyView(
                ZStack(alignment: .center) {
                    ProgressView(value: max(0.1, Float(progress ?? 10) / 100))
                        .progressViewStyle(DeterminiteSpinnerStyle())
                        .frame(width: 44, height: 44)
                        .spinning()

                    if let progress {
                        ThemeText(progress.description + "%", style: .captionSB, colorStyle: .primary)
                    }
                }
            )
        default:
            return nil
        }
    }
}

public struct CoinIconView: View {
    let coin: Coin?
    let placeholderImage: String?
    let maskImageUrl: String?
    let size: CGFloat
    let iconOpacity: Double
    let iconOverlay: AnyView?

    public init(coin: Coin?, placeholderImage: String? = nil, maskImageUrl: String? = nil, size: CGFloat = 40, iconOpacity: Double = 1, iconOverlay: AnyView? = nil) {
        self.coin = coin
        self.placeholderImage = placeholderImage
        self.maskImageUrl = maskImageUrl
        self.size = size
        self.iconOpacity = iconOpacity
        self.iconOverlay = iconOverlay
    }

    public init(token: Token?, size: CGFloat = 40, iconOpacity: Double = 1, iconOverlay: AnyView? = nil) {
        coin = token?.coin
        placeholderImage = token?.placeholderImageName
        maskImageUrl = token?.maskImageUrl
        self.size = size
        self.iconOpacity = iconOpacity
        self.iconOverlay = iconOverlay
    }

    public var body: some View {
        IconView(url: coin?.imageUrl, alternativeUrl: coin?.image, placeholderImage: placeholderImage, maskImageUrl: maskImageUrl, type: .circle, size: size, iconOpacity: iconOpacity, iconOverlay: iconOverlay)
    }
}

public struct IconView: View {
    let url: String?
    let alternativeUrl: String?
    let placeholderImage: String?
    let maskImageUrl: String?
    let type: IconType
    let size: CGFloat
    let iconOpacity: Double
    let iconOverlay: AnyView?

    public init(url: String?, alternativeUrl: String? = nil, placeholderImage: String? = nil, maskImageUrl: String? = nil, type: IconType = .circle, size: CGFloat = 40, iconOpacity: Double = 1, iconOverlay: AnyView? = nil) {
        self.url = url
        self.alternativeUrl = alternativeUrl
        self.placeholderImage = placeholderImage
        self.maskImageUrl = maskImageUrl
        self.type = type
        self.size = size
        self.iconOpacity = iconOpacity
        self.iconOverlay = iconOverlay
    }

    public var body: some View {
        if let alternativeUrl, let alternativeURL = URL(string: alternativeUrl) {
            if ImageCache.default.isCached(forKey: alternativeUrl) {
                icon(url: alternativeURL)

            } else {
                icon(url: url.flatMap { URL(string: $0) }, alternativeSources: [.network(alternativeURL)])
            }
        } else {
            icon(url: url.flatMap { URL(string: $0) })
        }
    }

    @ViewBuilder private func icon(url: URL?, alternativeSources: [Source]? = nil) -> some View {
        let base = rawIcon(url: url, alternativeSources: alternativeSources)
            .opacity(iconOpacity)
            .overlay {
                if let iconOverlay {
                    iconOverlay
                }
            }

        if let maskImageUrl {
            base
                .mask(alignment: .bottomTrailing) {
                    ZStack(alignment: .bottomTrailing) {
                        Rectangle()
                            .padding(-size) // extend beyond icon bounds so oversized overlays are not clipped
                        RoundedRectangle(cornerRadius: size * 6 / 40)
                            .frame(size: size * 18 / 40)
                            .offset(x: size * 3 / 40, y: size * 3 / 40)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                }
                .overlay(alignment: .bottomTrailing) {
                    KFImage.url(URL(string: maskImageUrl))
                        .placeholder { RoundedRectangle(cornerRadius: size * 5 / 40).fill(Color.themeBlade) }
                        .resizable()
                        .frame(size: size * 16 / 40)
                        .clipShape(RoundedRectangle(cornerRadius: size * 5 / 40))
                        .offset(x: size * 2 / 40, y: size * 2 / 40)
                }
        } else {
            base
        }
    }

    @ViewBuilder private func rawIcon(url: URL?, alternativeSources: [Source]? = nil) -> some View {
        KFImage.url(url)
            .alternativeSources(alternativeSources)
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
            .clipShape(type)
            .frame(width: size, height: size)
    }

    public enum IconType: Shape {
        case circle
        case squircle

        public func path(in rect: CGRect) -> Path {
            switch self {
            case .circle:
                return Circle().path(in: rect)
            case .squircle:
                return RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous).path(in: rect)
            }
        }
    }
}
