import MarketKit
import SwiftUI

struct AddressViewNew: View {
    private let maxLineLimit = 6
    private let placeholder = "send.address_or_domain_placeholder".localized

    @StateObject var viewModel: AddressViewModelNew

    @Binding var text: String
    @Binding var result: AddressInput.Result
    @Binding var borderColor: Color

    init(initial: AddressInput.Initial, text: Binding<String>, result: Binding<AddressInput.Result>, borderColor: Binding<Color>) {
        _viewModel = StateObject(wrappedValue: AddressViewModelNew(initial: initial))

        _text = text
        _result = result
        _borderColor = borderColor
    }

    var body: some View {
        InputTextRow(vertical: .margin8, borderColor: $borderColor) {
            ShortcutButtonsView(
                content: {
                    textField(
                        placeholder: placeholder,
                        text: $viewModel.text
                    )
                    .onAppear {
                        viewModel.text = text
                    }
                    .onChange(of: text) { newText in
                        if newText != viewModel.text {
                            viewModel.text = newText
                        }
                    }
                    .onChange(of: viewModel.text) { newText in
                        if newText != text {
                            text = newText
                        }
                    }
                    .onChange(of: viewModel.result) { newResult in
                        if newResult != result {
                            result = newResult
                        }
                    }
                    .font(.themeBody)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .modifier(RightChecking(state: $viewModel.checkingState))
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
