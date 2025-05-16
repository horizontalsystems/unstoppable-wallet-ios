import ComponentKit
import MarketKit
import SwiftUI

struct MultiSwapSendView: View {
    @StateObject var sendViewModel: SendViewModel
    @Binding private var swapPresentationMode: PresentationMode

    init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, swapPresentationMode: Binding<PresentationMode>) {
        _sendViewModel = .init(wrappedValue: SendViewModel(sendData: .swap(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider)))
        _swapPresentationMode = swapPresentationMode
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                SendView(viewModel: sendViewModel)
            } bottomContent: {
                switch sendViewModel.state {
                case .syncing:
                    EmptyView()
                case .success:
                    VStack(spacing: .margin24) {
                        if sendViewModel.timeLeft > 0 || sendViewModel.sending {
                            SlideButton(
                                styling: .text(start: "swap.confirmation.slide_to_swap".localized, end: "", success: ""),
                                action: {
                                    try await sendViewModel.send()
                                }, completion: {
                                    HudHelper.instance.show(banner: .swapped)
                                    swapPresentationMode.dismiss()
                                }
                            )
                        } else {
                            Button(action: {
                                sendViewModel.sync()
                            }) {
                                Text("send.confirmation.refresh".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .default))
                        }

                        let (bottomText, bottomTextColor) = bottomText()

                        Text(bottomText).textSubhead1(color: bottomTextColor)
                    }
                case .failed:
                    Button(action: {
                        sendViewModel.sync()
                    }) {
                        Text("send.confirmation.refresh".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .default))

                    Text("swap.confirmation.quote_failed".localized).textSubhead1()
                }
            }
        }
        .navigationTitle("send.confirmation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bottomText() -> (String, Color) {
        if let data = sendViewModel.state.data, !data.canSend {
            return ("swap.confirmation.invalid_quote".localized, .themeGray)
        } else if sendViewModel.sending {
            return ("swap.confirmation.please_wait".localized, .themeGray)
        } else if sendViewModel.timeLeft > 0 {
            return ("swap.confirmation.quote_expires_in".localized("\(sendViewModel.timeLeft)"), .themeJacob)
        } else {
            return ("swap.confirmation.quote_expired".localized, .themeGray)
        }
    }
}
