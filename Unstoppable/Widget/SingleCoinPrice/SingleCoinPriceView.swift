import Charts
import SwiftUI

struct SingleCoinPriceView: View {
    var entry: SingleCoinPriceProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: .margin8) {
            HStack(spacing: .margin8) {
                if let coinIcon = entry.icon {
                    coinIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: .iconSize32, height: .iconSize32)
                } else {
                    Circle()
                        .fill(Color.themeGray)
                        .frame(width: .iconSize32, height: .iconSize32)
                }

                Text(entry.code.uppercased())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.themeLeah)
                    .font(.themeSubhead1)
            }

            if #available(iOS 16.0, *), let chartPoints = entry.chartPoints {
                let values = chartPoints.map(\.value)

                if let firstValue = values.first, let lastValue = values.last, let minValue = values.min(), let maxValue = values.max() {
                    Chart {
                        ForEach(chartPoints) { point in
                            LineMark(
                                x: .value(String("Date"), point.date),
                                y: .value(String("Price"), point.value)
                            )
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: [minValue, maxValue])
                    .foregroundColor(firstValue <= lastValue ? .themeRemus : .themeLucian)
                    .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                }
            } else {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.priceChange)
                    .font(.themeSubhead2)
                    .foregroundColor(entry.priceChangeType.color)

                Text(entry.price)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 26)
                    .minimumScaleFactor(0.5)
                    .font(.themeHeadline1)
                    .foregroundColor(.themeLeah)
            }
        }
        .padding(.margin16)
        .widgetURL(URL(string: "unstoppable.money://coin/\(entry.uid)")!)
    }
}
