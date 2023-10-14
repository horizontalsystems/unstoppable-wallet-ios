import Charts
import SwiftUI

struct SingleCoinPriceView: View {
    var entry: SingleCoinPriceProvider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: .margin8) {
                if let coinIcon = entry.coinIcon {
                    coinIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: .iconSize32, height: .iconSize32)
                } else {
                    Circle()
                        .fill(Color.themeGray)
                        .frame(width: .iconSize32, height: .iconSize32)
                }

                Text(entry.coinCode.uppercased())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.themeLeah)
                    .font(.themeSubhead1)
            }

            if #available(iOS 16.0, *) {
                if let chartPoints = entry.chartPoints {
                    let values = chartPoints.map { $0.value }

                    if let firstValue = values.first, let lastValue = values.last, let minValue = values.min(), let maxValue = values.max() {
                        Chart {
                            ForEach(chartPoints) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Price", point.value)
                                )
                            }
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .chartYScale(domain: [minValue, maxValue])
                        .foregroundColor(firstValue <= lastValue ? .themeRemus : .themeLucian)
                        .frame(maxHeight: .infinity)
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 1) {
                if let formattedValue = ValueFormatter.format(percentValue: entry.priceChange) {
                    Text(formattedValue)
                        .font(.themeSubhead2)
                        .foregroundColor(entry.priceChange >= 0 ? .themeRemus : .themeLucian)
                }

                Text(String("$\(entry.price)".prefix(8)))
                    .font(.themeHeadline1)
                    .foregroundColor(.themeLeah)
            }
        }
    }
}
