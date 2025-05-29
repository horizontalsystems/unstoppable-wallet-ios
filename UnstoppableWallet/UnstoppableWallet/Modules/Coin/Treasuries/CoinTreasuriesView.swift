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
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(treasuries):
                VStack(spacing: 0) {
                    header()

                    ScrollViewReader { proxy in
                        ThemeList(bottomSpacing: .margin32) {
                            list(treasuries: treasuries)
                            footer()
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        }
                        .onChange(of: viewModel.filter) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
                        .onChange(of: viewModel.sortOrder) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
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
        .navigationTitle("coin_analytics.treasuries".localized)
    }

    @ViewBuilder private func header(disabled: Bool = false) -> some View {
        HorizontalDivider(color: .themeSteel10)
        HStack {
            HStack {
                Button(action: {
                    filterSelectorPresented = true
                }) {
                    Text(viewModel.filter.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .transparent, rightAccessory: .dropDown))
                .disabled(disabled)
            }
            .alert(
                isPresented: $filterSelectorPresented,
                title: "coin_analytics.treasuries.filters".localized,
                viewItems: CoinTreasuriesViewModel.Filter.allCases.map { .init(text: $0.title, selected: viewModel.filter == $0) },
                onTap: { index in
                    guard let index else {
                        return
                    }

                    viewModel.filter = CoinTreasuriesViewModel.Filter.allCases[index]
                }
            )

            Spacer()

            Button(action: {
                viewModel.sortOrder.toggle()
            }) {
                sortIcon().renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            .padding(.trailing, .margin16)
            .disabled(disabled)
        }
        .padding(.vertical, .margin8)
    }

    @ViewBuilder private func list(treasuries: [CoinTreasury]) -> some View {
        ListForEach(treasuries) { treasury in
            ListRow {
                itemContent(
                    imageUrl: URL(string: treasury.fundLogoUrl),
                    fund: treasury.fund,
                    amount: ValueFormatter.instance.formatShort(value: treasury.amount, decimalCount: 8, symbol: viewModel.coinCode) ?? "---",
                    country: treasury.country,
                    amountInCurrency: ValueFormatter.instance.formatShort(currency: viewModel.currency, value: treasury.amountInCurrency) ?? "---"
                )
            }
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
                    imageUrl: nil,
                    fund: "Unstoppable",
                    amount: "123.45 BTC",
                    country: "KG",
                    amountInCurrency: "$123.45"
                )
                .redacted()
            }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(imageUrl: URL?, fund: String, amount: String, country: String, amountInCurrency: String) -> some View {
        KFImage.url(imageUrl)
            .resizable()
            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeSteel20) }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
            .frame(width: .iconSize32, height: .iconSize32)

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

    private func sortIcon() -> Image {
        switch viewModel.sortOrder {
        case .asc: return Image("sort_l2h_20")
        case .desc: return Image("sort_h2l_20")
        }
    }
}
