import MarketKit
import SwiftUI

struct MarketGlobalView: View {
    @ObservedObject var viewModel: MarketGlobalViewModel

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                itemView(
                    title: "market.global.market_cap".localized,
                    amount: viewModel.marketGlobal?.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
                    diff: viewModel.marketGlobal?.marketCapChange.map { .percent(value: $0) },
                    redacted: viewModel.marketGlobal
                ) {
                    Coordinator.shared.present { isPresented in
                        MarketMarketCapView(isPresented: isPresented)
                    }
                    stat(page: .markets, event: .open(page: .globalMetricsMarketCap))
                }
                divider()
                itemView(
                    title: "market.global.volume".localized,
                    amount: viewModel.marketGlobal?.volume.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
                    diff: viewModel.marketGlobal?.volumeChange.map { .percent(value: $0) },
                    redacted: viewModel.marketGlobal
                ) {
                    Coordinator.shared.present { isPresented in
                        MarketVolumeView(isPresented: isPresented)
                    }
                    stat(page: .markets, event: .open(page: .globalMetricsVolume))
                }
                divider()
                itemView(
                    title: "market.global.tvl".localized,
                    amount: viewModel.marketGlobal?.tvl.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
                    diff: viewModel.marketGlobal?.tvlChange.map { .percent(value: $0) },
                    redacted: viewModel.marketGlobal
                ) {
                    Coordinator.shared.present { _ in
                        MarketTvlView()
                    }
                    stat(page: .markets, event: .open(page: .globalMetricsTvlInDefi))
                }
                divider()
                itemView(
                    title: "market.global.etf".localized,
                    amount: viewModel.marketGlobal?.etfTotalInflow.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
                    diff: viewModel.marketGlobal?.etfDailyInflow.map { .change(value: $0, currency: viewModel.currency) },
                    redacted: viewModel.marketGlobal
                ) {
                    Coordinator.shared.present { isPresented in
                        MarketEtfView(isPresented: isPresented)
                    }
                    stat(page: .markets, event: .open(page: .globalMetricsEtf))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .modifier(ThemeListStyleModifier())
        }
        .padding(.horizontal, .margin16)
        .padding(.vertical, .margin8)
        .animation(.default, value: viewModel.marketGlobal == nil)
    }

    @ViewBuilder private func itemView(title: String, amount: String?, diff: DiffText.Diff?, redacted: Any?, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: .margin4) {
            Text(title)
                .textMicroSB()
                .lineLimit(1)
                .truncationMode(.middle)

            Text(amount ?? "----")
                .textCaptionSB(color: .themeBran)
                .lineLimit(1)
                .truncationMode(.middle)
                .redacted(value: redacted)

            DiffText(diff, font: .themeCaption)
                .redacted(value: redacted)
        }
        .padding(.margin12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder private func divider() -> some View {
        Rectangle()
            .fill(Color.themeBlade)
            .frame(width: .heightOneDp)
    }
}
