import ComponentKit
import MarketKit
import SwiftUI

struct WalletConnectSendView: View {
    @StateObject var viewModel: WalletConnectSendViewModel
    @StateObject var sendViewModel: SendViewModel

    @Environment(\.presentationMode) private var presentationMode

    init(request: WalletConnectRequest) {
        _viewModel = .init(wrappedValue: WalletConnectSendViewModel(request: request))
        _sendViewModel = .init(wrappedValue: SendViewModel(sendData: .walletConnect(request: request)))
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                SendView(viewModel: sendViewModel)
            } bottomContent: {
                VStack(spacing: .margin16) {
                    switch sendViewModel.state {
                    case .syncing:
                        EmptyView()
                    case .success:
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
                        .buttonStyle(PrimaryButtonStyle(style: .active))
                        .disabled(sendViewModel.sending)
                    case .failed:
                        Button(action: {
                            sendViewModel.sync()
                        }) {
                            Text("send.confirmation.refresh".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .default))
                    }

                    Button(action: {
                        viewModel.reject()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("button.reject".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .default))
                    .disabled(sendViewModel.sending)
                }
            }
        }
        .navigationTitle(viewModel.dAppName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
