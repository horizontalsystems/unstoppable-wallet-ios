import MarketKit
import SwiftUI

// CrossPay entry screen (ZEC token page → Pay): recipient token/address/exact amount, live ZEC
// cost, then review — the confirmation screen commits the real order.
struct CrossPayView: View {
    @StateObject private var viewModel: CrossPayViewModel
    @Binding var isPresented: Bool

    private var addressBorderColor: Color {
        viewModel.recipientResult.isInvalid ? .themeLucian : .themeBlade
    }

    init(wallet: Wallet, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: CrossPayViewModel(wallet: wallet))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin16) {
                            balanceView()
                            tokenView()

                            if let tokenOut = viewModel.tokenOut {
                                addressView(tokenOut: tokenOut)
                                amountView()
                                quoteView()
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                } bottomContent: {
                    ThemeButton(text: "cross_pay.review".localized) {
                        if let request = viewModel.reviewRequest {
                            presentConfirmation(request: request)
                        }
                    }
                    .disabled(!viewModel.canReview)
                }
            }
            .navigationTitle("cross_pay.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }

    private func presentTokenSelect() {
        Coordinator.shared.present { isPresented in
            MultiSwapTokenSelectView(
                title: "cross_pay.send_to".localized,
                currentToken: $viewModel.selectedTokenOut,
                otherToken: viewModel.tokenIn,
                allowExternalReceive: true,
                isPresented: isPresented
            )
        }
    }

    private func presentConfirmation(request: CrossPayRequest) {
        Coordinator.shared.present { confirmPresented in
            RegularSendViewWrapper(
                sendData: .crossPay(request: request),
                // nil: the handler saves the recipient under the destination chain itself.
                address: nil,
                isPresented: confirmPresented,
                onSuccess: {
                    HudHelper.instance.show(banner: .sent)
                    isPresented = false
                }
            )
        }
    }

    @ViewBuilder private func balanceView() -> some View {
        ListSection {
            Cell(
                middle: {
                    MiddleTextIcon(text: "send.available_balance".localized)
                },
                right: {
                    RightTextIcon(text: balanceText)
                }
            )
        }
    }

    private var balanceText: String {
        guard let balance = viewModel.availableBalance else { return "n/a".localized }
        return formatted(amount: balance, token: viewModel.tokenIn)
    }

    @ViewBuilder private func tokenView() -> some View {
        ListSection {
            ClickableRow {
                presentTokenSelect()
            } content: {
                Text("cross_pay.send_to".localized).textSubhead2()

                Spacer()

                if let tokenOut = viewModel.tokenOut {
                    Text(tokenOut.coin.code).textSubhead2(color: .themeLeah)
                } else {
                    Text("cross_pay.select_token".localized).textSubhead2()
                }

                Image("arrow_small_down_20").themeIcon()
            }
        }
    }

    @ViewBuilder private func addressView(tokenOut: Token) -> some View {
        AddressViewNew(
            initial: .init(blockchainType: tokenOut.blockchainType, showContacts: true),
            text: $viewModel.recipientText,
            result: $viewModel.recipientResult,
            parserFilter: nil,
            borderColor: Binding(get: { addressBorderColor }, set: { _ in })
        )
        // Re-created per target token: the parser chain is built once at init.
        .id(tokenOut.tokenQuery.id)
    }

    @ViewBuilder private func amountView() -> some View {
        VStack(spacing: 3) {
            TextField("", text: $viewModel.amountString, prompt: Text("0").foregroundColor(.themeGray))
                .foregroundColor(.themeLeah)
                .font(.themeHeadline1)
                .tint(.themeInputFieldTintColor)
                .keyboardType(.decimalPad)

            if let coinPrice = viewModel.coinPrice {
                HStack(spacing: 0) {
                    Text(viewModel.currency.symbol).textBody(color: .themeGray)

                    TextField("", text: $viewModel.fiatAmountString, prompt: Text("0").foregroundColor(.themeGray))
                        .foregroundColor(.themeGray)
                        .font(.themeBody)
                        .tint(.themeInputFieldTintColor)
                        .keyboardType(.decimalPad)
                        .frame(height: 20)
                        .disabled(coinPrice.expired)
                }
            } else {
                Text("swap.rate_not_available".localized)
                    .themeSubhead2(color: .themeGray50, alignment: .leading)
                    .frame(height: 20)
            }
        }
        .padding(.horizontal, .margin16)
        .padding(.vertical, 20)
        .modifier(ThemeListStyleModifier(themeListStyle: .borderedLawrence))
    }

    @ViewBuilder private func quoteView() -> some View {
        switch viewModel.quoteState {
        case .none:
            EmptyView()
        case .loading:
            HStack {
                ProgressView()
                Spacer()
            }
        case let .success(sellAmount):
            let insufficient = viewModel.availableBalance.map { sellAmount > $0 } ?? false

            HStack {
                Text("cross_pay.you_pay".localized).textSubhead2()
                Spacer()
                Text(formatted(amount: sellAmount, token: viewModel.tokenIn))
                    .textSubhead2(color: insufficient ? .themeLucian : .themeLeah)
            }
            .padding(.horizontal, .margin16)
        case let .error(error):
            Text(error.errorDescription ?? "cross_pay.error.commit_failed".localized)
                .themeSubhead2(color: .themeLucian, alignment: .leading)
                .padding(.horizontal, .margin16)
        }
    }

    private func formatted(amount: Decimal, token: Token) -> String {
        let figure = ValueFormatter.instance.formatFull(value: amount, decimalCount: token.decimals) ?? "\(amount)"
        return "\(figure) \(token.coin.code)"
    }
}
