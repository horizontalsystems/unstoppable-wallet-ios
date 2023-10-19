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
        ListSection {
            ForEach(entry.items, id: \.uid) { item in
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
                .padding(.horizontal, .margin16)
                .frame(maxHeight: .infinity)
            }
        }
        .listStyle(.transparent)
        .frame(maxHeight: .infinity)
        .padding(.vertical, .margin4)
    }

    @ViewBuilder private func mediumView() -> some View {
        ListSection {
            ForEach(entry.items, id: \.uid) { item in
                row(item: item)
            }
        }
        .listStyle(.transparent)
        .frame(maxHeight: .infinity)
        .padding(.vertical, .margin4)
    }

    @ViewBuilder private func largeView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Text(entry.title)
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

            ListSection {
                ForEach(entry.items, id: \.uid) { item in
                    row(item: item)
                }
            }
            .listStyle(.transparent)
            .frame(maxHeight: .infinity)
        }
        .padding(.vertical, .margin4)
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
        .padding(.horizontal, .margin16)
        .frame(maxHeight: .infinity)
    }
}
