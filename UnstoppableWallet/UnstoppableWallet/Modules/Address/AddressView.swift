import ComponentKit
import SwiftUI
import ThemeKit

struct AddressView: View {
    @StateObject var viewModel: AddressViewModel
    private var onFinish: (ResolvedAddress) -> Void

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, address: String? = nil, onFinish: @escaping (ResolvedAddress) -> Void) {
        _viewModel = StateObject(wrappedValue: AddressViewModel(wallet: wallet, address: address))
        self.onFinish = onFinish
    }

    var body: some View {
        BottomGradientWrapper {
            ScrollView {
                VStack(spacing: .margin16) {
                    AddressViewNew(
                        initial: .init(
                            blockchainType: viewModel.token.blockchainType,
                            showContacts: true
                        ),
                        text: $viewModel.address,
                        result: $viewModel.addressResult
                    )
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin16, trailing: .margin16))
            }
        } bottomContent: {
            let (title, disabled, showProgress) = buttonState()

            Button(action: {
                guard case let .valid(address) = viewModel.state else {
                    return
                }

                onFinish(ResolvedAddress(address: address))
            }) {
                HStack(spacing: .margin8) {
                    if showProgress {
                        ProgressView()
                    }

                    Text(title)
                }
            }
            .disabled(disabled)
            .buttonStyle(PrimaryButtonStyle(style: .yellow))
        }
    }

    private func buttonState() -> (String, Bool, Bool) {
        let title: String
        var disabled = true
        var showProgress = false

        if case .empty = viewModel.state {
            title = "send.enter_address".localized
        } else if case .invalid = viewModel.state {
            title = "send.invalid_address".localized
        } else {
            title = "send.next_button".localized
            disabled = false
        }

        return (title, disabled, showProgress)
    }
}
