import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapConfirmView: View {
    @ObservedObject var viewModel: MultiSwapViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeView {
            VStack {
                ScrollView {
                    VStack(spacing: .margin16) {
                        ListSection {
                            if let tokenIn = viewModel.tokenIn, let amountIn = viewModel.amountIn {
                                tokenRow(title: "You Send", token: tokenIn, amount: amountIn, fiatAmount: viewModel.fiatAmountIn)
                            }

                            if let tokenOut = viewModel.tokenOut, let amountOut = viewModel.currentQuote?.quote.amountOut {
                                tokenRow(title: "You Get", token: tokenOut, amount: amountOut, fiatAmount: viewModel.fiatAmountOut)
                            }
                        }

                        if let price = viewModel.price {
                            ListSection {
                                ListRow {
                                    Text("Price").textSubhead2()

                                    Spacer()

                                    Button(action: {
                                        viewModel.flipPrice()
                                    }) {
                                        Text(price).textSubhead1(color: .themeLeah)
                                    }
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }

                Button(action: {
                    viewModel.swap()
                }) {
                    Text("Swap")
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .padding(.vertical, .margin16)
                .padding(.horizontal, .margin16)
            }
        }
        .navigationTitle("Confirm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                isPresented = false
            }
        }
    }

    @ViewBuilder private func tokenRow(title: String, token: Token, amount: Decimal, fiatAmount: Decimal?) -> some View {
        ListRow {
            KFImage.url(URL(string: token.coin.imageUrl))
                .resizable()
                .placeholder {
                    Circle().fill(Color.themeSteel20)
                }
                .clipShape(Circle())
                .frame(width: .iconSize24, height: .iconSize24)

            VStack(spacing: 1) {
                HStack(spacing: .margin4) {
                    Text(title).textSubhead2(color: .themeLeah)

                    Spacer()

                    if let formatted = ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: token), value: amount)) {
                        Text(formatted).textSubhead1(color: .themeLeah)
                    }
                }

                HStack(spacing: .margin4) {
                    if let protocolName = token.protocolName {
                        Text(protocolName).textCaption()
                    }

                    Spacer()

                    if let fiatAmount, let formatted = ValueFormatter.instance.formatFull(currency: viewModel.currency, value: fiatAmount) {
                        Text(formatted).textCaption()
                    }
                }
            }
        }
    }
}
