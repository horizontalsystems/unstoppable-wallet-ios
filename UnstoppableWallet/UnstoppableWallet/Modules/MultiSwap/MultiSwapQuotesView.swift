import SwiftUI

struct MultiSwapQuotesView: View {
    @ObservedObject var viewModel: MultiSwapViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationView {
            ScrollableThemeView {
                VStack {
                    ForEach(viewModel.quotes, id: \.provider.id) { (quote: MultiSwapViewModel.Quote) in
                        ListSection {
                            ClickableRow(action: {
                                viewModel.userSelectedProviderId = quote.provider.id
                                isPresented = false
                            }) {
                                Image(quote.provider.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: .iconSize32, height: .iconSize32)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(quote.provider.name).textSubhead2(color: .themeLeah)

                                    if quote.provider.id == viewModel.bestQuote?.provider.id {
                                        Text("Best Price").textSubhead2(color: .themeRemus)
                                    }

                                    if quote.provider.id == viewModel.currentQuote?.provider.id {
                                        Text("Current").textSubhead2(color: .themeJacob)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 1) {
                                    if let tokenOut = viewModel.tokenOut, let formatted = ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: tokenOut), value: quote.quote.amountOut)) {
                                        Text(formatted).textSubhead2(color: .themeLeah)
                                    } else {
                                        Text("n/a").textSubhead2(color: .themeGray50)
                                    }

                                    if let feeQuote = quote.quote.feeQuote,
                                       let feeToken = viewModel.feeToken,
                                       let fee = viewModel.feeService?.fee(quote: feeQuote, token: feeToken),
                                       let formatted = ValueFormatter.instance.formatShort(coinValue: fee)
                                    {
                                        Text(formatted).textSubhead2(color: .themeGray)
                                    } else {
                                        Text("n/a").textSubhead2(color: .themeGray50)
                                    }
                                }
                            }
                        }
                        .themeListStyle(.bordered)
                        .padding(.bottom, .margin8)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("Providers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.done".localized) {
                    isPresented = false
                }
            }
        }
    }
}
