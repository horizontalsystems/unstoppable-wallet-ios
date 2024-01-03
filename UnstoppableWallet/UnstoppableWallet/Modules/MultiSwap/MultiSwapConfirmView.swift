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
                            ListRow {
                                Image("arrow_medium_2_up_right_24").themeIcon()
                                Text("You Send").textBody()
                                Spacer()

                                if let tokenIn = viewModel.tokenIn {
                                    Text(tokenIn.coin.name).textSubhead1()
                                }
                            }

                            if let tokenIn = viewModel.tokenIn, let amountIn = viewModel.amountIn {
                                tokenRow(token: tokenIn, amount: amountIn, convertedString: viewModel.fiatAmountString)
                            }
                        }

                        ListSection {
                            ListRow {
                                Image("arrow_medium_2_down_left_24").themeIcon()
                                Text("You Get").textBody()
                                Spacer()

                                if let tokenOut = viewModel.tokenOut {
                                    Text(tokenOut.coin.name).textSubhead1()
                                }
                            }

                            if let tokenOut = viewModel.tokenOut, let amountOut = viewModel.currentQuote?.quote.amountOut {
                                tokenRow(token: tokenOut, amount: amountOut, convertedString: viewModel.fiatAmountOutString)
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

    @ViewBuilder private func tokenRow(token: Token, amount: Decimal, convertedString: String?) -> some View {
        ListRow {
            KFImage.url(URL(string: token.coin.imageUrl))
                .resizable()
                .placeholder {
                    Circle().fill(Color.themeSteel20)
                }
                .clipShape(Circle())
                .frame(width: .iconSize32, height: .iconSize32)

            if let formatted = ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: token), value: amount)) {
                Text(formatted).textSubhead1(color: .themeLeah)
            }

            Spacer()

            if let convertedString {
                Text(convertedString).textSubhead1()
            }
        }
    }
}
