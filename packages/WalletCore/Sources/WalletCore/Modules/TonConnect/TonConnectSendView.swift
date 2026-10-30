import MarketKit
import SwiftUI

struct TonConnectSendView: View {
    @StateObject var viewModel: TonConnectSendViewModel
    @StateObject var sendViewModel: SendViewModel

    @Environment(\.presentationMode) private var presentationMode

    init(request: TonConnectSendTransactionRequest) {
        _viewModel = .init(wrappedValue: TonConnectSendViewModel(request: request))
        _sendViewModel = .init(wrappedValue: SendViewModel(sendData: .tonConnect(request: request)))
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    SendView(viewModel: sendViewModel)
                } bottomContent: {
                    VStack(spacing: .margin16) {
                        switch sendViewModel.state {
                        case .syncing:
                            EmptyView()
                        case .success:
                            ThemeButton(text: "wallet_connect.button.confirm".localized) {
                                Task {
                                    try await sendViewModel.send()

                                    await MainActor.run {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                            .disabled(sendViewModel.sending)
                        case .failed:
                            ThemeButton(text: "send.confirmation.refresh".localized, style: .secondary) {
                                sendViewModel.sync()
                            }
                        }

                        ThemeButton(text: "button.reject".localized, style: .secondary) {
                            viewModel.reject()
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(sendViewModel.sending)
                    }
                }
            }
            .navigationTitle(viewModel.appName)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
}
