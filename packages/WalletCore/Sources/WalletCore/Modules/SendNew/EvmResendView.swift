import SwiftUI

struct EvmResendView: View {
    @StateObject private var viewModel: SendViewModel
    let type: ResendTransactionType
    let onSuccess: () -> Void

    init(viewModel: SendViewModel, type: ResendTransactionType, onSuccess: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: viewModel)
        self.type = type
        self.onSuccess = onSuccess
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                SendView(viewModel: viewModel, onSendError: { error in
                    HudHelper.instance.show(banner: .error(string: error))
                })
            } bottomContent: {
                if case .failed = viewModel.state {
                    ThemeButton(text: "send.confirmation.refresh".localized, style: .secondary) {
                        viewModel.sync()
                    }
                } else {
                    Button(action: send) {
                        Text((type == .speedUp ? "send.confirmation.resend" : "send.confirmation.cancel").localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                    .disabled(!viewModel.state.isSuccess || !viewModel.canSend || viewModel.sending)
                }
            }
        }
        .navigationTitle((type == .speedUp ? "tx_info.options.speed_up" : "tx_info.options.cancel").localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() {
        Task { @MainActor in
            HudHelper.instance.show(banner: .sending)
            do {
                try await viewModel.send()
                HudHelper.instance.show(banner: .sent)
                onSuccess()
            } catch {
                // SendView receives the error through SendViewModel.errorPublisher.
            }
        }
    }
}
