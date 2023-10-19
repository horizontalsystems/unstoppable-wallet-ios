import Charts
import SwiftUI
import WidgetKit

struct CoinPriceListView: View {
    var entry: CoinPriceListProvider.Entry

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
                Text(entry.mode.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.themeSubhead1)
                    .foregroundColor(.themeLeah)

                Text(entry.sortType)
                    .frame(maxWidth: .infinity, alignment: .trailing)
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

    @ViewBuilder private func list(verticalPadding: CGFloat, rowBuilder: @escaping (CoinPriceListEntry.Item) -> some View) -> some View {
        if entry.mode.isWatchlist, entry.items.isEmpty {
            VStack(spacing: .margin16) {
                switch family {
                case .systemLarge:
                    ZStack {
                        Circle()
                            .fill(Color.themeRaina)
                            .frame(width: 100, height: 100)

                        Image("rate_48")
                            .renderingMode(.template)
                            .foregroundColor(.themeGray)
                    }
                default:
                    EmptyView()
                }

                Text("Your watchlist is empty.")
                    .multilineTextAlignment(.center)
                    .font(.themeSubhead2)
                    .foregroundColor(.themeGray)
            }
            .frame(maxHeight: .infinity)
            .padding(.margin16)
        } else {
            GeometryReader { proxy in
                ListSection {
                    ForEach(entry.items, id: \.uid) { item in
                        rowBuilder(item)
                            .padding(.horizontal, .margin16)
                            .frame(maxHeight: .infinity)
                            .frame(maxHeight: proxy.size.height / CGFloat(entry.maxItemCount))
                    }

                    if entry.items.count < entry.maxItemCount {
                        Spacer()
                    }
                }
                .listStyle(.transparent)
            }
            .frame(maxHeight: .infinity)
            .padding(.vertical, verticalPadding)
        }
    }

    @ViewBuilder private func row(item: CoinPriceListEntry.Item) -> some View {
        HStack(spacing: .margin16) {
            icon(image: item.icon)

            VStack(spacing: 1) {
                HStack(spacing: .margin16) {
                    Text(item.code.uppercased())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)

                    Text(item.price)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)
                }

                HStack(spacing: .margin16) {
                    Text(item.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.themeSubhead2)
                        .foregroundColor(.themeGray)

                    Text(item.priceChange)
                        .font(.themeSubhead2)
                        .foregroundColor(item.priceChangeType.color)
                }
            }
        }
    }

    @ViewBuilder private func icon(image: Image?) -> some View {
        if let image = image {
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
