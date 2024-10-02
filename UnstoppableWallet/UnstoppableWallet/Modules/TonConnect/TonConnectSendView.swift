import ComponentKit
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
        ThemeNavigationView {
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
                            .buttonStyle(PrimaryButtonStyle(style: .yellow))
                            .disabled(sendViewModel.sending)
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
    }
}
