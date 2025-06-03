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
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                case let .loaded(rankedEtfs):
                    ScrollViewReader { proxy in
                        ThemeList(bottomSpacing: .margin16) {
                            header()
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)

                            chart()
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)

                            list(rankedEtfs: rankedEtfs)
                        }
                        .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
                        .onChange(of: viewModel.timePeriod) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
                    }
                case .failed:
                    VStack(spacing: 0) {
                        header()

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

            KFImage.url(URL(string: "ETF_bitcoin".headerImageUrl))
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

    @ViewBuilder private func list(rankedEtfs: [RankedEtf]) -> some View {
        Section {
            ListForEach(rankedEtfs) { rankedEtf in
                let etf = rankedEtf.etf

                ListRow {
                    itemContent(
                        imageUrl: URL(string: etf.imageUrl),
                        ticker: etf.ticker,
                        name: etf.name,
                        rank: rankedEtf.rank,
                        totalAssets: etf.totalAssets,
                        change: etf.inflow(timePeriod: viewModel.timePeriod)
                    )
                }
            }
        } header: {
            listHeader()
                .listRowInsets(EdgeInsets())
                .background(Color.themeTyler)
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        Section {
            ListForEach(Array(0 ... 10)) { index in
                ListRow {
                    itemContent(
                        imageUrl: nil,
                        ticker: "ABCD",
                        name: "Ticker Name",
                        rank: 12,
                        totalAssets: 123_345_678,
                        change: index % 2 == 0 ? 123_456 : -123_456
                    )
                    .redacted()
                }
            }
        } header: {
            listHeader()
                .listRowInsets(EdgeInsets())
                .background(Color.themeTyler)
        }
    }

    @ViewBuilder private func itemContent(imageUrl: URL?, ticker: String, name: String, rank: Int, totalAssets: Decimal?, change: Decimal?) -> some View {
        KFImage.url(imageUrl)
            .resizable()
            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text(ticker).textBody()
                Spacer()
                Text(totalAssets.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized).textBody()
            }

            HStack(spacing: .margin8) {
                HStack(spacing: .margin4) {
                    BadgeViewNew(text: "\(rank)")
                    Text(name).textSubhead2()
                }
                Spacer()
                DiffText(change, currency: viewModel.currency)
            }
        }
    }
}
