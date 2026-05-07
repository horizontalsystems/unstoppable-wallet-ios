import SwiftUI

struct NoPasscodeView: View {
    let mode: Mode

    var body: some View {
        ThemeView {
            VStack(spacing: .margin32) {
                Image("attention_48").themeIcon()

                Text(mode.description)
                    .textBody(color: .themeGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, .margin48)
        }
    }
}

extension NoPasscodeView {
    enum Mode {
        case noPasscode
        case cannotCheckPasscode

        var description: String {
            switch self {
            case .noPasscode: return "no_passcode.info_text".localized
            case .cannotCheckPasscode: return "cannot_check_passcode.info_text".localized
            }
        }
    }
}

struct JailbreakView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ThemeView {
            VStack(spacing: .margin32) {
                VStack(spacing: .margin32) {
                    Image("attention_48").themeIcon()

                    Text("jailbreak.info_text".localized)
                        .textBody(color: .themeGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, .margin24)
                .frame(maxHeight: .infinity)

                Button(action: {
                    isPresented = false
                }) {
                    Text("button.i_understand".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
            .padding(.horizontal, .margin24)
            .padding(.bottom, .margin32)
        }
    }
}
