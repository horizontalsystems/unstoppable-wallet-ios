import Kingfisher
import MarketKit
import SwiftUI

struct RankView: View {
    @StateObject var viewModel: RankViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel

    @Environment(\.presentationMode) private var presentationMode

    @State private var presentedCoin: Coin?
    @State private var timePeriodSelectorPresented = false

    init(type: RankViewModel.RankType) {
        _viewModel = StateObject(wrappedValue: RankViewModel(type: type))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: type.statRankType))
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
                case let .loaded(items):
                    ScrollViewReader { proxy in
                        ThemeList(bottomSpacing: .margin16) {
                            header()
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)

                            list(items: items)
                        }
                        .onChange(of: viewModel.sortOrder) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
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
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(item: $presentedCoin) { coin in
                CoinPageView(coin: coin)
                    .onFirstAppear { stat(page: viewModel.type.statRankType, event: .openCoin(coinUid: coin.uid)) }
            }
        }
    }

    @ViewBuilder private func header() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                VStack(spacing: .margin8) {
                    Text(viewModel.type.title.localized).themeHeadline1()
                    Text(viewModel.type.description.localized).textSubhead2()
                }
                .padding(.vertical, .margin12)
                .fixedSize(horizontal: false, vertical: true)

                KFImage.url(URL(string: viewModel.type.imageUid.headerImageUrl))
                    .resizable()
                    .frame(width: 76, height: 108)
            }
            .padding(.leading, .margin16)

            Rectangle()
                .fill(Color.themeBlade)
                .frame(height: .heightOneDp)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func listHeader(disabled: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    viewModel.sortOrder.toggle()
                }) {
                    Text(viewModel.type.sortingField.localized)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .custom(image: sortIcon())))
                .disabled(disabled)

                if viewModel.timePeriods.count > 1 {
                    Button(action: {
                        timePeriodSelectorPresented = true
                    }) {
                        Text(viewModel.timePeriod.shortTitle)
                    }
                    .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                    .disabled(disabled)
                }
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
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

    @ViewBuilder private func list(items: [RankViewModel.Item]) -> some View {
        Section {
            ListForEach(items) { item in
                let coin = item.coin

                ClickableRow(action: {
                    presentedCoin = item.coin
                }) {
                    itemContent(
                        index: item.index,
                        coin: coin,
                        value: item.value
                    )
                }
                .watchlistSwipeActions(viewModel: watchlistViewModel, coinUid: coin.uid)
            }
        } header: {
            listHeader()
                .listRowInsets(EdgeInsets())
                .background(Color.themeTyler)
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        Section {
            ListForEach(Array(0 ... 10)) { _ in
                ListRow {
                    itemContent(
                        index: 1,
                        coin: nil,
                        value: 12345.45
                    )
                    .redacted()
                }
            }
        } header: {
            listHeader(disabled: true)
                .listRowInsets(EdgeInsets())
                .background(Color.themeTyler)
        }
    }

    @ViewBuilder private func itemContent(index: Int, coin: Coin?, value: Decimal) -> some View {
        Text(index.description)
            .textCaptionSB()
            .frame(minWidth: 24, alignment: .center)

        CoinIconView(coin: coin)

        VStack(alignment: .leading, spacing: 1) {
            Text(coin?.code ?? "CODE").textBody()
            Text(coin?.name ?? "COIN NAME").textSubhead2()
        }

        Spacer()
        if let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: value) {
            Text(formatted).textBody()
        }
    }

    private func sortIcon() -> Image {
        switch viewModel.sortOrder {
        case .asc: return Image("arrow_medium_2_up_20")
        case .desc: return Image("arrow_medium_2_down_20")
        }
    }
}
