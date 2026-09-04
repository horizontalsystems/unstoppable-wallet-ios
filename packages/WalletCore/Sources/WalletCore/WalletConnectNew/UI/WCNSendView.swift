import SwiftUI

struct WCNSendView: View {
    private let item: WCNRequestItem
    @StateObject private var sendViewModel: SendViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var finished = false

    init(item: WCNRequestItem, sendData: SendData) {
        self.item = item
        _sendViewModel = StateObject(wrappedValue: SendViewModel(sendData: sendData))
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
                            Button(action: {
                                Task {
                                    try await sendViewModel.send()
                                    await MainActor.run {
                                        finished = true
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }) {
                                Text(buttonTitle)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .yellow))
                            .disabled(sendViewModel.sending || !(sendViewModel.sendData?.canSend ?? false))
                        case .failed:
                            Button(action: { sendViewModel.sync() }) {
                                Text("send.confirmation.refresh".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .gray))
                        }

                        Button(action: {
                            reject()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("button.reject".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .gray))
                        .disabled(sendViewModel.sending)
                    }
                }
            }
            .onDisappear {
                // a blocked request is answered with an error as soon as the screen goes away
                if !finished, item.request?.isBlocked == true { reject() }
            }
            .navigationTitle(item.session.dAppName)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(sendViewModel.sending)
    }

    private var buttonTitle: String {
        sendViewModel.sendData?.customSendButtonTitle ?? "wallet_connect.button.confirm".localized
    }

    private func reject() {
        guard !finished, let kit = Core.shared.walletConnectNew?.startedKit else { return }
        finished = true
        Task { try? await kit.reject(item: item) }
    }
}
