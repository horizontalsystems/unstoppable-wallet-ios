import MarketKit
import SwiftUI

struct CoinReportsView: View {
    @StateObject var viewModel: CoinReportsViewModel

    @Environment(\.openURL) private var openURL

    init(coinUid: String) {
        _viewModel = StateObject(wrappedValue: CoinReportsViewModel(coinUid: coinUid))
    }

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(reports):
                list(reports: reports)
            case .failed:
                SyncErrorView {
                    viewModel.onRetry()
                }
            }
        }
        .navigationTitle("coin_analytics.reports".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func list(reports: [CoinReport]) -> some View {
        ScrollView {
            LazyVStack(spacing: .margin12) {
                ForEach(reports.indices, id: \.self) { index in
                    let report = reports[index]

                    ListSection {
                        ClickableRow(padding: EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: .margin16)) {
                            if let url = URL(string: report.url) {
                                openURL(url)
                            }
                        } content: {
                            VStack(alignment: .leading, spacing: .margin12) {
                                VStack(alignment: .leading, spacing: .margin8) {
                                    Text(report.author).themeCaptionSB()

                                    VStack(alignment: .leading, spacing: .margin6) {
                                        Text(report.title)
                                            .themeHeadline2()
                                            .lineLimit(3)

                                        Text(report.body)
                                            .themeSubhead2()
                                            .lineLimit(2)
                                    }
                                }

                                Text(DateHelper.instance.formatMonthYear(from: report.date)).themeMicro(color: .themeGray50)
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }
}
