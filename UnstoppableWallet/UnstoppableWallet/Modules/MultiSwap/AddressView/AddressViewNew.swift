import MarketKit
import SwiftUI

struct AddressViewNew: View {
    private let maxLineLimit = 6
    private let placeholder = "send.address_or_domain_placeholder".localized

    @StateObject private var viewModel: AddressViewModelNew

    init(initial: AddressInput.Initial, result: Binding<AddressInput.Result>) {
        _viewModel = StateObject(wrappedValue:
            AddressViewModelNew(
                initial: initial,
                result: result
            )
        )
    }

    var body: some View {
        InputTextRow(vertical: .margin8) {
            ShortcutButtonsView(
                content: {
                    textField(placeholder: placeholder,
                            text: $viewModel.text
                    )
                    .font(.themeBody)
                    .autocorrectionDisabled()
                },
                showDelete: .init(get: { !viewModel.text.isEmpty }, set: { _ in }),
                items: viewModel.shortcuts,
                onTap: {
                    viewModel.onTap(index: $0)
                }, onTapDelete: {
                    viewModel.onTapDelete()
                }
            )
        }
        .sheet(isPresented: $viewModel.qrScanPresented) {
            ScanQrViewNew(pasteEnabled: true) {
                viewModel.didFetch(qrText: $0)
            }
        }
    }

    @ViewBuilder func textField(placeholder: String, text: Binding<String>) -> some View {
        if #available(iOS 16, *) {
            TextField(
                placeholder,
                text: text,
                axis: .vertical
            )
            .lineLimit(1 ... maxLineLimit)
            .accentColor(.themeYellow)
        } else {
            TextField(
                placeholder,
                text: text
            )
            .accentColor(.themeYellow)
        }
    }
}
