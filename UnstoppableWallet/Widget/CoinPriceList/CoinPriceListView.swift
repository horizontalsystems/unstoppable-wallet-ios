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
                    .lineLimit(1)
                    .font(.themeSubhead1)
                    .foregroundColor(.themeLeah)

                Spacer()

                Text(title(sortType: entry.sortType))
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

                Text("watchlist.empty")
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
                        Link(destination: URL(string: "unstoppable.money://coin/\(item.uid)")!) {
                            rowBuilder(item)
                                .padding(.horizontal, .margin16)
                                .frame(maxHeight: .infinity)
                                .frame(maxHeight: proxy.size.height / CGFloat(entry.maxItemCount))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if entry.items.count < entry.maxItemCount {
                        Spacer()
                    }
                }
                .themeListStyle(.transparentInline)
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
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)

                    Spacer()

                    Text(item.price)
                        .font(.themeSubhead1)
                        .foregroundColor(.themeLeah)
                }

                HStack(spacing: .margin16) {
                    Text(item.name)
                        .font(.themeSubhead2)
                        .foregroundColor(.themeGray)

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

    private func title(sortType: SortType) -> LocalizedStringKey {
        switch sortType {
        case .highestCap, .unknown: return "sort_type.highest_cap"
        case .lowestCap: return "sort_type.lowest_cap"
        case .highestVolume: return "sort_type.highest_volume"
        case .lowestVolume: return "sort_type.lowest_volume"
        case .topGainers: return "sort_type.top_gainers"
        case .topLosers: return "sort_type.top_losers"
        }
    }
}
