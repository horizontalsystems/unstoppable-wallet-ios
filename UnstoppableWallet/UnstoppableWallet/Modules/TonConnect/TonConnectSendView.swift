
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
                            if sendViewModel.canSend, sendViewModel.handler?.expirationDuration == nil || sendViewModel.timeLeft > 0 || sendViewModel.sending {
                                Button(action: {
                                    Task {
                                        try await sendViewModel.send()

                                        await MainActor.run {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                }) {
                                    Text("wallet_connect.button.confirm".localized)
                                }
                                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                                .disabled(sendViewModel.sending)
                            } else {
                                Button(action: {
                                    sendViewModel.sync()
                                }) {
                                    Text("send.confirmation.refresh".localized)
                                }
                                .buttonStyle(PrimaryButtonStyle(style: .gray))
                            }
                        case .failed:
                            Button(action: {
                                sendViewModel.sync()
                            }) {
                                Text("send.confirmation.refresh".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .gray))
                        }

                        Button(action: {
                            viewModel.reject()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("button.reject".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .gray))
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
