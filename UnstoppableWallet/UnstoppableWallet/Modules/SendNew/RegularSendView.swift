
import MarketKit
import SwiftUI

struct RegularSendView: View {
    @StateObject var sendViewModel: SendViewModel

    private let onSuccess: () -> Void

    init(sendData: SendData, address: String? = nil, onSuccess: @escaping () -> Void) {
        _sendViewModel = .init(wrappedValue: SendViewModel(sendData: sendData, address: address))
        self.onSuccess = onSuccess
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                SendView(viewModel: sendViewModel)
            } bottomContent: {
                switch sendViewModel.state {
                case .syncing:
                    if sendViewModel.sendData != nil {
                        ThemeButton(text: "send.confirmation.refreshing".localized, spinner: true, style: .secondary) {}
                            .disabled(true)
                    }
                case .success:
                    if let sendData = sendViewModel.sendData, sendViewModel.canSend {
                        SlideButton(
                            styling: .text(start: sendData.customSendButtonTitle ?? "send.confirmation.slide_to_send".localized, end: "", success: ""),
                            action: {
                                try await sendViewModel.send()
                            }, completion: {
                                onSuccess()
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
        .navigationTitle("send.confirmation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RegularSendViewWrapper: View {
    let sendData: SendData
    let address: String?
    @Binding var isPresented: Bool
    let onSuccess: () -> Void

    @State private var path = NavigationPath()

    var body: some View {
        ThemeNavigationStack(path: $path) {
            RegularSendView(sendData: sendData, address: address) {
                isPresented = false
                onSuccess()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
