import Kingfisher
import MarketKit
import SwiftUI

struct BuyView: View {
    @StateObject private var viewModel: BuyViewModel

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.openURL) private var openURL
    @State private var currencySelectorPresented = false

    init(token: Token) {
        _viewModel = StateObject(wrappedValue: BuyViewModel(token: token))
    }

    var body: some View {
        ThemeView {
            VStack {
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Currency").textSubhead2()
                            Spacer()
                            Button(action: {
                                currencySelectorPresented = true
                            }) {
                                Text(viewModel.currency.code).textSubhead1(color: .themeLeah)
                            }
                            .sheet(isPresented: $currencySelectorPresented) {
                                CurrencySelector(
                                    viewModel: viewModel,
                                    isPresented: $currencySelectorPresented
                                )
                            }
                        }
                        .padding(.vertical, 10)

                        VStack(spacing: .margin16) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 0) {
                                    Text(viewModel.currency.symbol).textHeadline1()

                                    TextField(viewModel.defaultAmount.description, text: $viewModel.amountString)
                                        .foregroundColor(.themeLeah)
                                        .font(.themeHeadline1)
                                        .keyboardType(.decimalPad)
                                }

                                Text(viewModel.bestQuote.flatMap { ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: viewModel.token), value: $0.cryptoAmount)) } ?? "n/a").textCaption()
                                Text(viewModel.bestQuoteConvertedAmount.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a").textCaption()
                            }
                            .padding(.vertical, .margin24)
                            .padding(.horizontal, .margin16)
                            .modifier(ThemeListStyleModifier(themeListStyle: .lawrence))

                            if let quote = viewModel.bestQuote {
                                ClickableRow(action: {}) {
                                    KFImage.url(URL(string: quote.ramp.logoUrl))
                                        .resizable()
                                        .frame(width: .iconSize32, height: .iconSize32)

                                    HStack(spacing: .margin8) {
                                        VStack(spacing: 1) {
                                            HStack(spacing: .margin8) {
                                                Text(quote.ramp.title).textBody()
                                                Spacer()
//                                                Text(ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: viewModel.token), value: quote.cryptoAmount)) ?? "n/a").textBody()
                                            }

                                            HStack(spacing: .margin8) {
                                                Text("Best Price").textSubhead2(color: .themeRemus)
                                                Spacer()
//                                                Text("per BNB").textSubhead2()
                                            }
                                        }

                                        Image.disclosureIcon
                                    }
                                }
                                .modifier(ThemeListStyleModifier(themeListStyle: .lawrence))
                            }
                        }
                    }
                }

                Button(action: {
                    if let url = viewModel.bestQuote?.url {
                        openURL(url)
                    }
                }) {
                    Text("Buy \(viewModel.token.coin.code)")
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
        }
        .navigationTitle("Buy \(viewModel.token.coin.code)\(viewModel.token.badge.map { " (\($0))" } ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private struct CurrencySelector: View {
        let viewModel: BuyViewModel
        @Binding var isPresented: Bool

        var body: some View {
            ThemeNavigationView {
                ScrollableThemeView {
                    ListSection {
                        ForEach(viewModel.popularCurrencies) { currency in
                            row(currency: currency)
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))

                    VStack {
                        ListSectionHeader(text: "settings.base_currency.other".localized)

                        ListSection {
                            ForEach(viewModel.otherCurrencies) { currency in
                                row(currency: currency)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
                .navigationBarTitle("Currency")
                .toolbar {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
        }

        @ViewBuilder private func row(currency: Currency) -> some View {
            ClickableRow(action: {
                if viewModel.currency != currency {
                    viewModel.currency = currency
                }

                isPresented = false
            }) {
                Image(currency.code)

                VStack(spacing: 1) {
                    Text(currency.code).themeBody()
                    Text(currency.symbol).themeSubhead2()
                }

                if viewModel.currency == currency {
                    Image.checkIcon
                }
            }
        }
    }
}
