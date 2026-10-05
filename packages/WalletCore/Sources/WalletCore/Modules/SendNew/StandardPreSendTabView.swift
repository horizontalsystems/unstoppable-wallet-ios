import SwiftUI

struct StandardPreSendTabView: View {
    @ObservedObject var viewModel: PreSendViewModel
    let addressVisible: Bool

    @Binding var path: NavigationPath
    @Binding var isPresented: Bool

    var body: some View {
        PreSendFormView(viewModel: viewModel, addressVisible: addressVisible, path: $path, isPresented: $isPresented) { focus in
            if viewModel.memoType != .none {
                memoView(type: viewModel.memoType, focus: focus)
            }

            if viewModel.destinationTagState != .hidden {
                destinationTagView(state: viewModel.destinationTagState, focus: focus)
            }
        }
    }

    @ViewBuilder private func destinationTagView(state: DestinationTagState, focus: FocusState<PreSendFocusField?>.Binding) -> some View {
        let input = viewModel.destinationTag.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalid = !input.isEmpty && XrpDestinationTag.parse(input) == nil
        let infoText = invalid ? "send.xrp.destination_tag.invalid".localized : "send.xrp.destination_tag.info".localized
        let infoTextColorStyle: ColorStyle = invalid ? .red : (state == .required ? .yellow : .secondary)

        let fixedTag: UInt32? = {
            if case let .fixed(tag) = state { return tag }
            return nil
        }()
        let text: Binding<String> = fixedTag.map { .constant(String($0)) } ?? $viewModel.destinationTag

        VStack(alignment: .leading, spacing: 0) {
            InputTextView(
                placeholder: "send.xrp.destination_tag.title".localized,
                multiline: false,
                font: .themeBody,
                text: text
            )
            .keyboardType(.numberPad)
            .disabled(fixedTag != nil)
            .focused(focus, equals: .destinationTag)
            .padding(16)

            Color.themeBlade.frame(height: .heightOnePixel)

            ThemeText(infoText, style: .caption, colorStyle: infoTextColorStyle)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }

    @ViewBuilder private func memoView(type: MemoType, focus: FocusState<PreSendFocusField?>.Binding) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            InputTextView(
                placeholder: "send.confirmation.memo_placeholder".localized,
                multiline: true,
                font: .themeBody.italic(),
                text: $viewModel.memo
            )
            .focused(focus, equals: .memo)
            .padding(16)

            Color.themeBlade.frame(height: .heightOnePixel)

            ThemeText(memoInfoText(type: type), style: .caption)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }

    private func memoInfoText(type: MemoType) -> String {
        switch type {
        case .onChainPrivate: return "send.memo.private_warning".localized
        case .local: return "send.memo.local_warning".localized
        default: return "send.memo.public_warning".localized
        }
    }
}
