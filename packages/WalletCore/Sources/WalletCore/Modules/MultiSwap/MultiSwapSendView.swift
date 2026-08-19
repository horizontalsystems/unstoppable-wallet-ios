import MarketKit
import SwiftUI

struct MultiSwapSendView: View {
    @StateObject var sendViewModel: SendViewModel

    private let onFinish: () -> Void

    init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, multiSwapQuote: MultiSwapQuote, recipientHolder: SwapExternalRecipientHolder, onFinish: @escaping () -> Void) {
        _sendViewModel = .init(wrappedValue: SendViewModel(sendData: .swap(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, provider: provider, multiSwapQuote: multiSwapQuote, recipientHolder: recipientHolder)))
        self.onFinish = onFinish
    }

    private var showSlideButton: Bool {
        if sendViewModel.sending { return true }
        guard case .success = sendViewModel.state else { return false }
        return sendViewModel.canSend && !sendViewModel.expired
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                SendView(viewModel: sendViewModel)
            } bottomContent: {
                if showSlideButton {
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
                    switch sendViewModel.state {
                    case .syncing:
                        if sendViewModel.sendData != nil {
                            ThemeButton(text: "swap.quoting".localized, spinner: true, style: .secondary) {}
                                .disabled(true)
                        }
                    case .success, .failed:
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
