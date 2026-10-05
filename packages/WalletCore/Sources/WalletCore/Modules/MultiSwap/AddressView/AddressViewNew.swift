import MarketKit
import SwiftUI

struct AddressViewNew: View {
    private let maxLineLimit = 6
    private let placeholder = "send.address_or_domain_placeholder".localized

    @StateObject var viewModel: AddressViewModelNew

    @Binding var text: String
    @Binding var result: AddressInput.Result
    @Binding var borderColor: Color
    @Binding var foregroundColor: Color

    @State private var fieldText = ""

    init(initial: AddressInput.Initial, text: Binding<String>, result: Binding<AddressInput.Result>, parserFilter: AddressParserFactory.ParserFilter?, borderColor: Binding<Color>, foregroundColor: Binding<Color> = .constant(.themeLeah)) {
        _viewModel = StateObject(wrappedValue: AddressViewModelNew(initial: initial, parserFilter: parserFilter))

        _text = text
        _result = result
        _borderColor = borderColor
        _foregroundColor = foregroundColor
    }

    var body: some View {
        InputTextRow(borderColor: $borderColor) {
            PrimarySizedHStack {
                textField(
                    placeholder: placeholder,
                    text: $fieldText
                )
                .onAppear {
                    viewModel.text = text
                    fieldText = text
                }
                .onChange(of: fieldText) { _, fieldText in
                    if viewModel.text != fieldText {
                        viewModel.text = fieldText
                    }
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

                    // A vertical TextField keeps a stale height if its text and width change in the same
                    // layout pass (iOS 27), so external text is applied after the buttons have been laid out
                    DispatchQueue.main.async {
                        if fieldText != viewModel.text {
                            fieldText = viewModel.text
                        }
                    }
                }
                .onChange(of: viewModel.result) { newResult in
                    if newResult != result {
                        result = newResult
                    }
                }
                .font(.themeBody)
                .foregroundStyle(foregroundColor)
                .autocorrectionDisabled()
                .autocapitalization(.none)
            } trailing: {
                ShortcutButtonsView(
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
