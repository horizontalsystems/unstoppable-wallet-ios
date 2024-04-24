import SwiftUI
import ThemeKit

struct MarketGlobalView: View {
    @ObservedObject var viewModel: MarketGlobalViewModel

    @State private var presentedGlobalMarketMetricsType: MarketGlobalModule.MetricsType?

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                itemView(title: "market.global.market_cap".localized, item: viewModel.globalMarketData?.marketCap, metricsType: .totalMarketCap)
                divider()
                itemView(title: "market.global.volume".localized, item: viewModel.globalMarketData?.volume, metricsType: .volume24h)
                divider()
                itemView(title: "market.global.defi_cap".localized, item: viewModel.globalMarketData?.defiCap, metricsType: .defiCap)
                divider()
                itemView(title: "market.global.defi_in_tvl".localized, item: viewModel.globalMarketData?.tvlInDefi, metricsType: .tvlInDefi)
            }
            .padding(.horizontal, .margin4)
            .modifier(ThemeListStyleModifier())
            .animation(.default, value: viewModel.globalMarketData == nil)
        }
        .padding(.horizontal, .margin16)
        .padding(.top, .margin12)
        .padding(.bottom, .margin16)
        .sheet(item: $presentedGlobalMarketMetricsType) { metricsType in
            MarketGlobalMetricsView(metricsType: metricsType).ignoresSafeArea()
        }
    }

    @ViewBuilder private func itemView(title: String, item: MarketGlobalViewModel.GlobalMarketItem?, metricsType: MarketGlobalModule.MetricsType) -> some View {
        VStack(alignment: .leading, spacing: .margin8) {
            Text(title)
                .textCaption()
                .lineLimit(1)
                .truncationMode(.middle)

            VStack(alignment: .leading, spacing: 1) {
                Text(item?.amount ?? "$2.34T")
                    .textCaption(color: .themeBran)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .redacted(value: item?.amount)

                DiffText(item?.diff, font: .themeCaption)
                    .redacted(value: item?.diff)
            }
        }
        .padding(.horizontal, .margin8)
        .padding(.vertical, .margin12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture {
            presentedGlobalMarketMetricsType = metricsType
        }
    }

    @ViewBuilder private func divider() -> some View {
        Rectangle()
            .fill(Color.themeSteel20)
            .frame(width: .heightOneDp, height: 50)
    }
}
