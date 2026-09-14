import SwiftUI

struct BitcoinResendView: View {
    @StateObject var viewModel: SendViewModel
    let type: ResendTransactionType
    let onSuccess: () -> Void

    private var showSlider: Bool {
        viewModel.sending || (viewModel.state.isSuccess && viewModel.canSend && !viewModel.expired)
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                SendView(viewModel: viewModel, additionalContent: feeInput, onSendError: { error in
                    HudHelper.instance.show(banner: .error(string: error))
                })
            } bottomContent: {
                if showSlider {
                    SlideButton(
                        styling: .text(start: (type == .speedUp ? "send.confirmation.slide_to_resend" : "send.confirmation.slide_to_cancel").localized, end: "", success: ""),
                        action: { try await viewModel.send() },
                        completion: {
                            HudHelper.instance.show(banner: .sent)
                            onSuccess()
                        }
                    )
                } else {
                    ThemeButton(text: (viewModel.state.isSyncing ? "send.confirmation.refreshing" : "send.confirmation.refresh").localized,
                                spinner: viewModel.state.isSyncing, style: .secondary)
                    {
                        viewModel.sync()
                    }
                    .disabled(viewModel.state.isSyncing)
                }
            }
        }
        .navigationTitle((type == .speedUp ? "tx_info.options.speed_up" : "tx_info.options.cancel").localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var feeInput: AnyView? {
        guard let service = viewModel.transactionService as? BitcoinResendTransactionService else { return nil }
        return AnyView(BitcoinResendFeeView(service: service, cautionType: viewModel.cautions.first?.type).disabled(viewModel.sending))
    }
}

struct BitcoinResendFeeView: View {
    @ObservedObject var service: BitcoinResendTransactionService
    var cautionType: CautionType? = nil
    private let helper = FeeSettingsViewHelper()

    var body: some View {
        VStack(spacing: 0) {
            helper.headerRow(title: "send.confirmation.fee".localized + " (Sat)", infoDescription: .fee)
            helper.inputNumberWithSteps(
                text: Binding(get: { service.minFeeText }, set: { service.set(minFeeText: $0) }),
                cautionState: .constant((cautionType ?? service.cautions.first?.type).map { .caution($0) } ?? .none),
                onTap: service.step
            )
        }
        .padding(.top, .margin8)
    }
}
