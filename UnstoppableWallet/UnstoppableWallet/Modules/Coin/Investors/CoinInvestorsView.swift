import Kingfisher
import MarketKit
import SwiftUI

struct CoinInvestorsView: View {
    @StateObject var viewModel: CoinInvestorsViewModel

    init(coinUid: String) {
        _viewModel = StateObject(wrappedValue: CoinInvestorsViewModel(coinUid: coinUid))
    }

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(investments):
                list(investments: investments)
            case .failed:
                SyncErrorView {
                    viewModel.onRetry()
                }
            }
        }
        .navigationTitle("coin_analytics.funding".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func list(investments: [CoinInvestment]) -> some View {
        ScrollView {
            LazyVStack(spacing: .margin24) {
                ForEach(investments.indices, id: \.self) { index in
                    let investment = investments[index]

                    VStack(spacing: .margin12) {
                        VStack(spacing: 0) {
                            HorizontalDivider()

                            HStack(spacing: .margin8) {
                                Text(investment.amount.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.usdCurrency, value: $0) } ?? "---").textBody(color: .themeJacob)
                                Spacer()
                                Text("\(investment.round) - \(DateHelper.instance.formatFullDateOnly(from: investment.date))").textSubhead1(color: .themeLeah)
                            }
                            .padding(.horizontal, .margin16)
                            .padding(.vertical, .margin12)
                        }

                        ListSection {
                            ForEach(investment.funds.indices, id: \.self) { index in
                                let fund = investment.funds[index]

                                ClickableRow(spacing: .margin8) {
                                    UrlManager.open(url: fund.website)
                                } content: {
                                    HStack(spacing: .margin16) {
                                        KFImage.url(URL(string: fund.logoUrl))
                                            .resizable()
                                            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                                            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                                            .frame(width: .iconSize32, height: .iconSize32)

                                        Text(fund.name).textBody()
                                    }

                                    Spacer()

                                    if fund.isLead {
                                        Text("coin_analytics.funding.lead".localized).textSubhead1(color: .themeRemus)
                                    }

                                    Image.disclosureIcon
                                }
                            }
                        }
                        .padding(.horizontal, .margin16)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin32, trailing: 0))
        }
    }
}
