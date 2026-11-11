import SwiftUI

struct MnemonicInputView: View {
    let placeholder: String
    @Binding var value: CaretText
    let invalidRanges: [NSRange]
    var caution: CautionState = .none
    var cautionIdentifier: String?
    @Binding var isFocused: Bool
    let statPage: StatPage
    let statEntity: StatEntity
    var identifier: String?
    var buttonIdentifiers: ButtonIdentifiers?

    var body: some View {
        ThemeInput(
            kind: .area,
            caution: caution,
            descriptionIdentifier: cautionIdentifier,
            buttons: ThemeInputButton.shortcuts(
                isEmpty: value.text.isEmpty,
                whenEmpty: [
                    .scan(options: [.picker], identifier: buttonIdentifiers?.scan) { text in
                        value = .end(text)
                        stat(page: statPage, event: .scanQr(entity: statEntity))
                    },
                    .paste(identifier: buttonIdentifiers?.paste) { string in
                        value = .end(string)
                        stat(page: statPage, event: .paste(entity: statEntity))
                    },
                ],
                deleteIdentifier: buttonIdentifiers?.clear,
                onDelete: {
                    value = .end("")
                }
            )
        ) {
            ZStack(alignment: .topLeading) {
                if value.text.isEmpty {
                    ThemeText(placeholder, style: .body, colorStyle: .andy)
                }

                MnemonicTextView(value: $value, invalidRanges: invalidRanges, isFocused: $isFocused, identifier: identifier)
            }
            .onThemeInputFocusRequest {
                isFocused = true
            }
        }
        .animation(.default, value: value.text.isEmpty)
    }
}

extension MnemonicInputView {
    struct ButtonIdentifiers {
        let scan: String?
        let paste: String?
        let clear: String?
    }
}
