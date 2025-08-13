import Charts
import SwiftUI
import WidgetKit

struct CoinListView: View {
    let items: [CoinItem]
    let maxItemCount: Int
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall: smallView()
        case .systemMedium: mediumView()
        default: largeView()
        }
    }

    @ViewBuilder private func smallView() -> some View {
        list(verticalPadding: .margin4) { item in
            HStack(spacing: .margin8) {
                icon(image: item.icon)

                VStack(spacing: 1) {
                    Text(item.price)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)
                    Text(item.priceChange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.themeCaption)
                        .foregroundColor(item.priceChangeType.color)
                }
            }
        }
    }

    @ViewBuilder private func mediumView() -> some View {
        list(verticalPadding: .margin4) { item in
            row(item: item)
        }
    }

    @ViewBuilder private func largeView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Text(title)
                    .lineLimit(1)
                    .font(.themeSubhead1)
                    .foregroundColor(.themeLeah)

                Spacer()

                Text(subtitle)
                    .lineLimit(1)
                    .font(.themeSubhead2)
                    .foregroundColor(.themeGray)
            }
            .padding(.margin16)

            HorizontalDivider()

            list(verticalPadding: 0) { item in
                row(item: item)
            }
        }
        .padding(.vertical, .margin4)
    }

    @ViewBuilder private func list(verticalPadding: CGFloat, rowBuilder: @escaping (CoinItem) -> some View) -> some View {
        GeometryReader { proxy in
            ListSection {
                ForEach(items, id: \.uid) { item in
                    Link(destination: URL(string: "unstoppable.money://coin/\(item.uid)")!) {
                        rowBuilder(item)
                            .padding(.horizontal, .margin16)
                            .frame(maxHeight: .infinity)
                            .frame(maxHeight: proxy.size.height / CGFloat(maxItemCount))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if items.count < maxItemCount {
                    Spacer()
                }
            }
            .themeListStyle(.transparentInline)
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical, verticalPadding)
    }

    @ViewBuilder private func row(item: CoinItem) -> some View {
        HStack(spacing: .margin16) {
            icon(image: item.icon)

            VStack(spacing: 1) {
                HStack(spacing: .margin16) {
                    Text(item.code.uppercased())
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)

                    Spacer()

                    Text(item.price)
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)
                }

                HStack(spacing: .margin16) {
                    HStack(spacing: .margin4) {
                        if let rank = item.rank {
                            BadgeViewNew(rank)
                        }

                        if let marketCap = item.marketCap {
                            Text(marketCap)
                                .font(.themeSubhead2)
                                .foregroundColor(.themeGray)
                        }
                    }

                    Spacer()

                    Text(item.priceChange)
                        .font(.themeSubhead2)
                        .foregroundColor(item.priceChangeType.color)
                }
            }
        }
    }

    @ViewBuilder private func icon(image: Image?) -> some View {
        if let image {
            image
                .resizable()
                .scaledToFit()
                .frame(width: .iconSize32, height: .iconSize32)
        } else {
            Circle()
                .fill(Color.themeGray)
                .frame(width: .iconSize32, height: .iconSize32)
        }
    }
}
