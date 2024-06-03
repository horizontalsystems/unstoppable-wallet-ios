import Kingfisher
import MarketKit
import SwiftUI

struct CoinTreasuriesView: View {
    @StateObject var viewModel: CoinTreasuriesViewModel

    @State private var filterSelectorPresented = false

    init(coin: Coin) {
        _viewModel = StateObject(wrappedValue: CoinTreasuriesViewModel(coin: coin))
    }

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header()
                    loadingList()
                }
            case let .loaded(treasuries):
                VStack(spacing: 0) {
                    header()

                    ThemeList(bottomSpacing: .margin32) {
                        list(treasuries: treasuries)
                        footer()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    }
                }
            case .failed:
                SyncErrorView {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
    }

    @ViewBuilder private func header() -> some View {
        HorizontalDivider(color: .themeSteel10)
        HStack {
            HStack {
                Button(action: {
                    filterSelectorPresented = true
                }) {
                    Text(viewModel.filter.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .transparent, rightAccessory: .dropDown))
            }
            .alert(
                isPresented: $filterSelectorPresented,
                title: "coin_analytics.treasuries.filters".localized,
                viewItems: viewModel.filters.map { .init(text: $0.title, selected: viewModel.filter == $0) },
                onTap: { index in
                    guard let index else {
                        return
                    }

                    viewModel.filter = viewModel.filters[index]
                }
            )

            Spacer()

            Button(action: {
                viewModel.toggleSortBy()
            }) {
                Image(viewModel.orderedAscending ? "sort_l2h_20" : "sort_h2l_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            .padding(.trailing, .margin16)
        }
        .padding(.vertical, .margin8)
    }

    @ViewBuilder private func list(treasuries: [CoinTreasury]) -> some View {
        ListForEach(treasuries) { treasury in
            itemContent(
                logoUrl: treasury.fundLogoUrl,
                fund: treasury.fund,
                amount: ValueFormatter.instance.formatShort(value: treasury.amount, decimalCount: 8, symbol: viewModel.coinCode) ?? "---",
                country: treasury.country,
                amountInCurrency: ValueFormatter.instance.formatShort(currency: viewModel.currency, value: treasury.amountInCurrency) ?? "---"
            )
        }
    }

    @ViewBuilder private func footer() -> some View {
        Text("Powered by Bitcointreasuries.net")
            .textCaption(color: .themeGray)
            .padding(.top, .margin12)
            .padding(.horizontal, .margin24)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { _ in
            ListRow {
                itemContent(
                    logoUrl: nil,
                    fund: "",
                    amount: "",
                    country: "",
                    amountInCurrency: ""
                )
                .redacted()
            }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(logoUrl: String?, fund: String, amount: String, country: String, amountInCurrency: String) -> some View {
        ListRow {
            if let url = logoUrl.flatMap({ URL(string: $0) }) {
                KFImage.url(url)
                    .resizable()
                    .frame(width: .iconSize32, height: .iconSize32)
            }

            VStack(spacing: 1) {
                HStack(spacing: .margin8) {
                    Text(fund).textBody()
                    Spacer()
                    Text(amount).textBody()
                }

                HStack(spacing: .margin8) {
                    Text(country).textSubhead2()
                    Spacer()
                    Text(amountInCurrency).textSubhead2(color: .themeJacob)
                }
            }
        }
    }
}
