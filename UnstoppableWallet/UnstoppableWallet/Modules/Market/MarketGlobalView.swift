import MarketKit
import SwiftUI
import ThemeKit

struct MarketGlobalView: View {
    @ObservedObject var viewModel: MarketGlobalViewModel

    @State private var marketCapPresented = false
    @State private var volumePresented = false
    @State private var etfPresented = false
    @State private var tvlPresented = false

    var body: some View {
        VStack(spacing: 0) {
            if let marketGlobal = viewModel.marketGlobal {
                MarqueeView(targetVelocity: 30) {
                    content(marketGlobal: marketGlobal, redacted: marketGlobal)
                }
            } else {
                ZStack {
                    HStack(spacing: .margin8) {
                        content(marketGlobal: nil, redacted: nil)
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
        .animation(.default, value: viewModel.marketGlobal == nil)
        .sheet(isPresented: $tvlPresented) {
            MarketTvlView(isPresented: $tvlPresented)
        }
        .sheet(isPresented: $marketCapPresented) {
            MarketMarketCapView(isPresented: $marketCapPresented)
        }
        .sheet(isPresented: $volumePresented) {
            MarketVolumeView(isPresented: $volumePresented)
        }
        .sheet(isPresented: $etfPresented) {
            MarketEtfView(isPresented: $etfPresented)
        }
    }

    @ViewBuilder private func content(marketGlobal: MarketGlobal?, redacted: Any?) -> some View {
        diffView(
            title: "market.global.market_cap".localized,
            amount: marketGlobal?.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
            diff: marketGlobal?.marketCapChange.map { .percent(value: $0) },
            redacted: redacted
        ) {
            marketCapPresented = true
        }

        diffView(
            title: "market.global.volume".localized,
            amount: marketGlobal?.volume.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
            diff: marketGlobal?.volumeChange.map { .percent(value: $0) },
            redacted: redacted
        ) {
            volumePresented = true
        }

        diffView(
            title: "market.global.btc_dominance".localized,
            amount: marketGlobal?.btcDominance.flatMap { ValueFormatter.instance.format(percentValue: $0, showSign: false) },
            diff: marketGlobal?.btcDominanceChange.map { .percent(value: $0) },
            redacted: redacted
        ) {
            marketCapPresented = true
        }

        diffView(
            title: "market.global.etf_inflow".localized,
            amount: marketGlobal?.etfTotalInflow.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
            diff: marketGlobal?.etfDailyInflow.map { .change(value: $0, currency: viewModel.currency) },
            redacted: redacted
        ) {
            etfPresented = true
        }

        diffView(
            title: "market.global.tvl_in_defi".localized,
            amount: marketGlobal?.tvl.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
            diff: marketGlobal?.tvlChange.map { .percent(value: $0) },
            redacted: redacted
        ) {
            tvlPresented = true
        }
    }

    @ViewBuilder private func diffView(title: String, amount: String?, diff: DiffText.Diff?, redacted: Any?, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: .margin4) {
            Text(title).textCaption()

            Text(amount ?? "----")
                .textCaption(color: .themeBran)
                .redacted(value: redacted)

            DiffText(diff, font: .themeCaption)
                .redacted(value: redacted)
        }
        .padding(.horizontal, .margin8)
        .padding(.vertical, .margin16)
        .onTapGesture(perform: onTap)
    }
}
