import Kingfisher
import MarketKit
import SwiftUI

struct MarketEtfView: View {
    @StateObject var viewModel: MarketEtfViewModel
    @StateObject var chartViewModel: MetricChartViewModel
    @Binding var isPresented: Bool

    @State private var sortBySelectorPresented = false
    @State private var timePeriodSelectorPresented = false

    init(isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MarketEtfViewModel())
        _chartViewModel = StateObject(wrappedValue: MetricChartViewModel.etfInstance)
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                switch viewModel.state {
                case .loading:
                    VStack(spacing: 0) {
                        header()
                        chart()
                        listHeader(disabled: true)
                        loadingList()
                    }
                case let .loaded(etfs):
                    ThemeLazyList {
                        header()
                        chart()
                        list(etfs: etfs)
                    }
                    .themeListStyle(.transparent)
                case .failed:
                    VStack(spacing: 0) {
                        header()
                        chart()

                        SyncErrorView {
                            viewModel.sync()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder private func header() -> some View {
        HStack(spacing: .margin32) {
            VStack(spacing: .margin8) {
                Text("market.etf.title".localized).themeHeadline1()
                Text("market.etf.description".localized).themeSubhead2()
            }
            .padding(.vertical, .margin12)

            KFImage.url(URL(string: "https://cdn.blocksdecoded.com/category-icons/lending@3x.png"))
                .resizable()
                .frame(width: 76, height: 108)
        }
        .padding(.leading, .margin16)
    }

    @ViewBuilder private func chart() -> some View {
        ChartView(viewModel: chartViewModel, configuration: .baseHistogramChart)
            .frame(maxWidth: .infinity)
            .onFirstAppear {
                chartViewModel.start()
            }
    }

    @ViewBuilder private func listHeader(disabled: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    sortBySelectorPresented = true
                }) {
                    Text(viewModel.sortBy.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
                    timePeriodSelectorPresented = true
                }) {
                    Text(viewModel.timePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
        .alert(
            isPresented: $sortBySelectorPresented,
            title: "market.sort_by.title".localized,
            viewItems: MarketEtfViewModel.SortBy.allCases.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.sortBy = MarketEtfViewModel.SortBy.allCases[index]
            }
        )
        .alert(
            isPresented: $timePeriodSelectorPresented,
            title: "market.time_period.title".localized,
            viewItems: viewModel.timePeriods.map { .init(text: $0.title, selected: viewModel.timePeriod == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.timePeriod = viewModel.timePeriods[index]
            }
        )
    }

    @ViewBuilder private func list(etfs: [Etf]) -> some View {
        Section {
            ThemeLazyListSectionContent(items: etfs) { etf in
                ListRow {
                    itemContent(
                        imageUrl: nil,
                        ticker: etf.ticker,
                        name: etf.name,
                        totalAssets: etf.totalAssets,
                        change: etf.inflow(timePeriod: viewModel.timePeriod)
                    )
                }
            }
        } header: {
            listHeader().background(Color.themeTyler)
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(items: Array(0 ... 10)) { index in
            ListRow {
                itemContent(
                    imageUrl: nil,
                    ticker: "ABCD",
                    name: "Ticker Name",
                    totalAssets: 123_345_678,
                    change: index % 2 == 0 ? 123_456 : -123_456
                )
                .redacted()
            }
        }
        .themeListStyle(.transparent)
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(imageUrl: URL?, ticker: String, name: String, totalAssets: Decimal?, change: Decimal?) -> some View {
        KFImage.url(imageUrl)
            .resizable()
            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeSteel20) }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text(ticker).textBody()
                Spacer()
                Text(totalAssets.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized).textBody()
            }

            HStack(spacing: .margin8) {
                Text(name).textSubhead2()
                Spacer()

                if let change, let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: change) {
                    if change == 0 {
                        Text(formatted).textSubhead2()
                    } else if change > 0 {
                        Text("+\(formatted)").textSubhead2(color: .themeRemus)
                    } else {
                        Text("-\(formatted)").textSubhead2(color: .themeLucian)
                    }
                } else {
                    Text("----").textSubhead2()
                }
            }
        }
    }
}
