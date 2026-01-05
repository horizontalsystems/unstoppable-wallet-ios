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
                    if sendViewModel.sendData != nil {
                        ThemeButton(text: "swap.quoting".localized, spinner: true, style: .secondary) {}
                            .disabled(true)
                    }
                case .success:
                    if sendViewModel.canSend {
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
        .navigationTitle("swap.confirmation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
    }
}
