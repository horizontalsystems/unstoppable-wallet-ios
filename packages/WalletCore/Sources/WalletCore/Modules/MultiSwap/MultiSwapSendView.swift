import MarketKit
import SwiftUI

struct MultiSwapSendView: View {
    @StateObject var sendViewModel: SendViewModel

    private let onFinish: () -> Void

    init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, multiSwapQuote: MultiSwapQuote, onFinish: @escaping () -> Void) {
        _sendViewModel = .init(wrappedValue: SendViewModel(sendData: .swap(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider, multiSwapQuote: multiSwapQuote)))
        self.onFinish = onFinish
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                SendView(viewModel: sendViewModel)
            } bottomContent: {
                // A live send outranks every quote state (a StellarBroker session can run for
                // minutes, and a sync landing mid-send can still move the screen to .failed).
                // Checked ABOVE the switch so no branch can offer Refresh — re-quoting during a
                // send would let a second committed quote race the one being executed.
                // Safe: SlideButton runs its action in an unstructured Task that survives
                // being replaced here.
                if sendViewModel.sending {
                    ThemeButton(text: "send.confirmation.sending".localized, spinner: true, style: .secondary) {}
                        .disabled(true)
                } else {
                    switch sendViewModel.state {
                    case .syncing:
                        if sendViewModel.sendData != nil {
                            ThemeButton(text: "swap.quoting".localized, spinner: true, style: .secondary) {}
                                .disabled(true)
                        }
                    case .success:
                        if sendViewModel.canSend, !sendViewModel.expired {
                            SlideButton(
                                styling: .text(start: "swap.confirmation.slide_to_swap".localized, end: "", success: ""),
                                action: {
                                    try await sendViewModel.send()
                                }, completion: {
                                    HudHelper.instance.show(banner: .swapped)
                                    onFinish()
                                }
                            )
                        } else {
                            ThemeButton(text: "send.confirmation.refresh".localized, style: .secondary) {
                                sendViewModel.sync()
                            }
                        }
                    case .failed:
                        ThemeButton(text: "send.confirmation.refresh".localized, style: .secondary) {
                            sendViewModel.sync()
                        }
                    }
                }
            }
        }
        .navigationTitle("swap.confirmation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
    }
}
