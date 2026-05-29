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
        list(verticalPadding: 4) { item in
            HStack(spacing: 8) {
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
        list(verticalPadding: 4) { item in
            row(item: item)
        }
    }

    @ViewBuilder private func largeView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
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
            .padding(16)

            HorizontalDivider()

            list(verticalPadding: 0) { item in
                row(item: item)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private func list(verticalPadding: CGFloat, rowBuilder: @escaping (CoinItem) -> some View) -> some View {
        GeometryReader { proxy in
            ListSection {
                ForEach(items) { item in
                    Link(destination: URL(string: "unstoppable.money://coin/\(item.uid)")!) {
                        rowBuilder(item)
                            .padding(.horizontal, 16)
                            .frame(maxHeight: .infinity)
                            .frame(maxHeight: proxy.size.height / CGFloat(maxItemCount))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if items.count < maxItemCount {
                    Spacer()
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical, verticalPadding)
    }

    @ViewBuilder private func row(item: CoinItem) -> some View {
        HStack(spacing: 16) {
            icon(image: item.icon)

            VStack(spacing: 1) {
                HStack(spacing: 16) {
                    Text(item.code.uppercased())
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)

                    Spacer()

                    Text(item.price)
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)
                }

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        if let rank = item.rank {
                            BadgeView(text: rank)
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
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.themeGray)
                .frame(width: 32, height: 32)
        }
    }
}
