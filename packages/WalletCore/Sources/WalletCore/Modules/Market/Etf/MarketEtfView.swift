import Kingfisher
import MarketKit
import SwiftUI

struct MarketEtfView: View {
    @ObservedObject var viewModel: MarketEtfViewModel
    @ObservedObject var chartViewModel: MetricChartViewModel

    init(category: MarketEtfFetcher.EtfCategory, factory: MarketEtfViewModelFactory) {
        viewModel = factory.getViewModel(for: category)
        chartViewModel = factory.getChartViewModel(for: category)
    }

    var body: some View {
        VStack {
            switch viewModel.state {
            case .loading:
                loadingList()
            case let .loaded(rankedEtfs):
                ScrollViewReader { proxy in
                    ThemeList(bottomSpacing: .margin16) {
                        header()
                            .listRowBackground(Color.themeTyler)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .themeListTopView()

                        chart()
                            .listRowBackground(Color.themeTyler)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)

                        list(rankedEtfs: rankedEtfs)
                    }
                    .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                    .onChange(of: viewModel.timePeriod) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                    .themeListScrollHeader()
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
    }

    @ViewBuilder private func header() -> some View {
        HStack(alignment: .top, spacing: .margin32) {
            Text("market.etf.description".localized(viewModel.category.title)).themeSubhead2()
                .padding(.top, .margin24)

            KFImage.url(URL(string: "ETF_\(viewModel.category.icon)".headerImageUrl))
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
        ListHeader(scrollable: true) {
            DropdownButton(text: viewModel.sortBy.title) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "market.sort_by.title".localized,
                        viewItems: MarketEtfViewModel.SortBy.allCases.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
                        onSelect: { index in
                            viewModel.sortBy = MarketEtfViewModel.SortBy.allCases[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)

            DropdownButton(text: viewModel.timePeriod.shortTitle) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "market.time_period.title".localized,
                        viewItems: viewModel.timePeriods.map { .init(text: $0.title, selected: viewModel.timePeriod == $0) },
                        onSelect: { index in
                            viewModel.timePeriod = viewModel.timePeriods[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)
        }
    }

    @ViewBuilder private func list(rankedEtfs: [RankedEtf]) -> some View {
        Section {
            ListForEach(rankedEtfs) { rankedEtf in
                let etf = rankedEtf.etf

                cell(
                    imageUrl: URL(string: etf.imageUrl),
                    ticker: etf.ticker,
                    name: etf.name,
                    rank: rankedEtf.rank,
                    totalAssets: etf.totalAssets,
                    change: etf.inflow(timePeriod: viewModel.timePeriod)
                )
            }
        } header: {
            listHeader()
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(bottomSpacing: .margin16) {
            header()
                .listRowBackground(Color.themeTyler)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

            ZStack {
                ProgressView()
            }
            .frame(height: 277) // TODO: use real chart height (after migrating to Swift Charts)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.themeTyler)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            Section {
                ListForEach(Array(0 ... 10)) { index in
                    cell(
                        imageUrl: nil,
                        ticker: "ABCD",
                        name: "Ticker Name",
                        rank: 12,
                        totalAssets: 123_345_678,
                        change: index % 2 == 0 ? 123_456 : -123_456
                    )
                    .redacted()
                }
            } header: {
                listHeader(disabled: true)
            }
        }
        .scrollDisabled(true)
    }

    @ViewBuilder private func cell(imageUrl: URL?, ticker: String, name: String, rank: Int, totalAssets: Decimal?, change: Decimal?) -> some View {
        Cell(
            left: {
                KFImage.url(imageUrl)
                    .resizable()
                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                    .frame(width: .iconSize32, height: .iconSize32)

            },
            middle: {
                MultiText(
                    title: ticker,
                    subtitleBadge: "\(rank)",
                    subtitle: name
                )
            },
            right: {
                RightMultiText(
                    title: totalAssets.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    subtitle: Diff.text(diff: change.map { Diff.change(value: $0, currency: viewModel.currency) })
                )
            }
        )
    }
}
