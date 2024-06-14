import MarketKit
import SwiftUI

struct CoinMajorHoldersView: View {
    @StateObject var viewModel: CoinMajorHoldersViewModel
    @Binding var isPresented: Bool

    @Environment(\.openURL) private var openURL

    init(coin: Coin, blockchain: Blockchain, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: CoinMajorHoldersViewModel(coin: coin, blockchain: blockchain))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case let .loaded(stateViewItem):
                    content(stateViewItem: stateViewItem)
                case .failed:
                    SyncErrorView {
                        viewModel.onRetry()
                    }
                }
            }
            .navigationTitle(viewModel.blockchain.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.close".localized) {
                    isPresented = false
                }
            }
        }
    }

    @ViewBuilder private func content(stateViewItem: CoinMajorHoldersViewModel.StateViewItem) -> some View {
        ThemeList(bottomSpacing: .margin32) {
            VStack(spacing: .margin12) {
                if let percent = stateViewItem.percent {
                    HStack(alignment: .firstTextBaseline, spacing: .margin8) {
                        Text(percent).textHeadline1()
                        Text("coin_analytics.holders.in_top_10_addresses".localized).textSubhead1()
                        Spacer()
                    }
                }

                if let count = stateViewItem.holdersCount {
                    Text("coin_analytics.holders.count".localized(count)).themeSubhead2()
                }

                let chartColor = viewModel.blockchain.type.brandColorNew ?? .themeJacob

                CoinHoldersChart(items: [
                    (stateViewItem.totalPercent / 100.0, chartColor),
                    (stateViewItem.remainingPercent / 100.0, chartColor.opacity(0.5)),
                ])
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin24, trailing: .margin16))
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            ListForEach(stateViewItem.viewItems) { viewItem in
                ListRow {
                    Text(viewItem.order).textCaptionSB()

                    VStack(alignment: .leading, spacing: 1) {
                        if let percent = viewItem.percent {
                            Text(percent).textBody()
                        }

                        if let quantity = viewItem.quantity {
                            Text(quantity).textSubhead2()
                        }
                    }

                    Spacer()

                    Button {
                        CopyHelper.copyAndNotify(value: viewItem.address)
                    } label: {
                        Text(viewItem.labeledAddress)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }

            if let holdersUrl = stateViewItem.holdersUrl, let url = URL(string: holdersUrl) {
                ListSection {
                    ClickableRow(spacing: .margin8) {
                        openURL(url)
                    } content: {
                        Text("coin_analytics.holders.see_all".localized).textBody()
                        Spacer()
                        Image.disclosureIcon
                    }
                }
                .padding(.horizontal, .margin16)
                .padding(.top, .margin32)
                .themeListStyle(.lawrence)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
    }
}
