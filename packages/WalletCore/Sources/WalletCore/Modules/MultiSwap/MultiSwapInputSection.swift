import MarketKit
import SwiftUI

/// Available balance, the You Pay / You Get boxes and the interchange button, bound to one swap view
/// model. Shared by the Standard and Private tabs of MultiSwapView, each with its own view model.
struct MultiSwapInputSection: View {
    @ObservedObject var viewModel: MultiSwapViewModel
    var focusedField: FocusState<MultiSwapView.FocusField?>.Binding
    let allowExternalReceive: Bool

    var body: some View {
        VStack(spacing: 0) {
            AvailableBalanceView(
                // a balance read mid-sync is not the real one yet
                balance: viewModel.tokenInWalletState == .ready ? viewModel.availableBalance : nil,
                token: viewModel.tokenIn,
                allAvailable: viewModel.tokenInWalletState == .ready && viewModel.percentAllAvailable,
                currentValue: viewModel.amountIn,
                onSelect: { percent in
                    viewModel.setAmountIn(percent: percent)
                    focusedField.wrappedValue = nil
                },
                onClear: {
                    viewModel.clearAmountIn()
                }
            )
            .padding(.top, 16)
            .padding(.horizontal, 16)

            amountsView()
        }
    }

    private func amountsView() -> some View {
        VStack(spacing: 0) {
            boxInView()
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)

            boxSeparatorView()

            boxOutView()
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)

            Color.themeBlade.frame(height: .heightOnePixel)
        }
    }

    private func boxInView() -> some View {
        SendInputView(
            token: viewModel.tokenIn,
            amountDecimals: viewModel.amountInDecimals,
            amountString: $viewModel.amountString,
            fiatAmountString: $viewModel.fiatAmountString,
            coinPrice: viewModel.coinPriceIn,
            currency: viewModel.currency,
            focusedField: focusedField,
            amountField: .amount,
            fiatField: .fiat,
            amountIdentifier: TestTags.swapAmountIn,
            tokenIdentifier: TestTags.swapTokenIn
        ) {
            Coordinator.shared.present { isPresented in
                MultiSwapTokenSelectView(
                    title: "swap.you_pay".localized,
                    currentToken: $viewModel.tokenIn,
                    otherToken: viewModel.tokenOut,
                    isPresented: isPresented
                )
            }
        }
    }

    private func boxSeparatorView() -> some View {
        Color.themeBlade.frame(height: .heightOnePixel)
            .overlay {
                IconButton(icon: "arrow_m_down", style: .secondary, size: .small) {
                    viewModel.interchange()
                }
                .disabled(viewModel.externalRecipientRequired)
                .accessibilityIdentifier(TestTags.swapSwitch)
            }
    }

    private func boxOutView() -> some View {
        HStack(spacing: 8) {
            TokenSelectorButton(token: viewModel.tokenOut) {
                Coordinator.shared.present { isPresented in
                    MultiSwapTokenSelectView(
                        title: "swap.you_get".localized,
                        currentToken: $viewModel.tokenOut,
                        otherToken: viewModel.tokenIn,
                        allowExternalReceive: allowExternalReceive,
                        isPresented: isPresented
                    )
                }
            }
            .accessibilityIdentifier(TestTags.swapTokenOut)

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                if let amountOut = viewModel.amountOut, let tokenOut = viewModel.tokenOut,
                   let formatted = ValueFormatter.instance.formatFull(value: amountOut, decimalCount: tokenOut.decimals)
                {
                    ThemeText(formatted, style: .headline1)
                        .lineLimit(1)
                        .accessibilityIdentifier(TestTags.swapAmountOut)
                } else {
                    ThemeText("0", style: .headline1, colorStyle: .secondary)
                        .accessibilityIdentifier(TestTags.swapAmountOut)
                }

                if viewModel.tokenOut != nil {
                    if viewModel.rateOut != nil {
                        HStack(spacing: 8) {
                            Spacer()

                            ThemeText("\(viewModel.currency.symbol)\((viewModel.fiatAmountOut ?? 0).description)", style: .body, colorStyle: viewModel.fiatAmountOut == nil ? .andy : .secondary)
                                .frame(height: 22)

                            if let priceImpact = viewModel.priceImpact {
                                let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

                                switch level {
                                case .negligible, .low:
                                    EmptyView()
                                default:
                                    ThemeText("(\(PriceImpact.display(value: priceImpact)))", style: .body, colorStyle: level.valueLevel.colorStyle)
                                }
                            }
                        }
                    } else {
                        ThemeText("n/a".localized, style: .body, colorStyle: .andy)
                            .frame(height: 22)
                    }
                } else {
                    ThemeText("\(viewModel.currency.symbol)0", style: .body, colorStyle: .andy)
                        .frame(height: 22)
                }
            }
        }
    }
}
