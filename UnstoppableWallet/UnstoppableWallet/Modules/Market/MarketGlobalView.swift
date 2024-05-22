import SwiftUI
import ThemeKit

struct MarketGlobalView: View {
    @ObservedObject var viewModel: MarketGlobalViewModel

    @State private var presentedGlobalMarketMetricsType: MarketGlobalModule.MetricsType?
    @State private var etfPresented = false

    var body: some View {
        VStack(spacing: 0) {
            if let globalMarketData = viewModel.globalMarketData {
                MarqueeView(targetVelocity: 30) {
                    content(globalMarketData: globalMarketData)
                }
            } else {
                ZStack {
                    HStack(spacing: .margin8) {
                        content(globalMarketData: nil)
                    }
                    .padding(.leading, .margin8)
                    .fixedSize()
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }

            Rectangle()
                .fill(Color.themeSteel10)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
        }
        .animation(.default, value: viewModel.globalMarketData == nil)
        .sheet(item: $presentedGlobalMarketMetricsType) { metricsType in
            MarketGlobalMetricsView(metricsType: metricsType).ignoresSafeArea()
        }
        .sheet(isPresented: $etfPresented) {
            MarketEtfView(isPresented: $etfPresented)
        }
    }

    @ViewBuilder private func content(globalMarketData: MarketGlobalViewModel.GlobalMarketData?) -> some View {
        itemView(title: "market.global.market_cap".localized, item: globalMarketData?.marketCap, metricsType: .totalMarketCap)
        itemView(title: "market.global.volume".localized, item: globalMarketData?.volume, metricsType: .volume24h)
        itemView(title: "market.global.defi_cap".localized, item: globalMarketData?.defiCap, metricsType: .defiCap)
        itemView(title: "market.global.defi_in_tvl".localized, item: globalMarketData?.tvlInDefi, metricsType: .tvlInDefi)
    }

    @ViewBuilder private func itemView(title: String, item: MarketGlobalViewModel.GlobalMarketItem?, metricsType: MarketGlobalModule.MetricsType) -> some View {
        HStack(spacing: .margin4) {
            Text(title).textCaption()

            Text(item?.amount ?? "$2.34T")
                .textCaption(color: .themeBran)
                .redacted(value: item?.amount)

            DiffText(item?.diff, font: .themeCaption)
                .redacted(value: item?.diff)
        }
        .padding(.horizontal, .margin8)
        .padding(.vertical, .margin16)
        .onTapGesture {
            switch metricsType {
            case .defiCap: etfPresented = true
            default: presentedGlobalMarketMetricsType = metricsType
            }
        }
    }
}
