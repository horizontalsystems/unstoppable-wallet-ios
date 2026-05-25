import Combine
import SwiftUI
import WalletCore

struct MnemonicInputCellWrapper: UIViewRepresentable {
    private static let appearDuration: TimeInterval = 0.5

    let statPage: StatPage
    let placeholder: String
    @Binding var invalidRanges: [NSRange]
    let cautionType: CautionType?
    let replaceWordPublisher: AnyPublisher<(NSRange, String), Never>
    @Binding var heightTrigger: Bool
    @Binding var isFocused: Bool
    let onChangeMnemonicText: (String, Int) -> Void
    let onChangeEntering: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MnemonicInputCell {
        let coordinator = context.coordinator
        let binding = $heightTrigger

        let cell = MnemonicInputCell(statPage: statPage, statEntity: .recoveryPhrase)
        cell.contentView.backgroundColor = .clear
        cell.set(placeholderText: placeholder)

        cell.onChangeMnemonicText = { text, cursorOffset in
            DispatchQueue.main.async {
                onChangeMnemonicText(text, cursorOffset)
            }
        }
        cell.onChangeEntering = { [weak cell] in
            guard let cell else { return }
            onChangeEntering(cell.entering)
        }
        cell.onChangeHeight = {
            DispatchQueue.main.async {
                binding.wrappedValue.toggle()
            }
        }
        cell.onOpenViewController = { [weak cell] vc in
            cell?.parentViewController?.present(vc, animated: true)
        }

        coordinator.cancellable = replaceWordPublisher.sink { [weak cell] range, word in
            DispatchQueue.main.async {
                cell?.replaceWord(range: range, word: word)
            }
        }

        let defaultWords = AppConfig.defaultWords
        if !defaultWords.isEmpty {
            cell.set(text: defaultWords)
        }

        return cell
    }

    func updateUIView(_ uiView: MnemonicInputCell, context: Context) {
        uiView.set(invalidRanges: invalidRanges)
        uiView.set(cautionType: cautionType)

        let coord = context.coordinator
        guard isFocused != coord.lastIsFocused else { return }
        coord.lastIsFocused = isFocused

        if isFocused {
            let delay: TimeInterval = coord.didFirstFocus ? 0 : Self.appearDuration
            coord.didFirstFocus = true
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak uiView] in
                _ = uiView?.becomeFirstResponder()
            }
        } else {
            uiView.endEditing(true)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MnemonicInputCell, context _: Context) -> CGSize? {
        let _ = heightTrigger
        let width = proposal.width ?? UIScreen.main.bounds.width
        return CGSize(width: width, height: uiView.cellHeight(containerWidth: width))
    }

    class Coordinator {
        var cancellable: AnyCancellable?
        var didFirstFocus = false
        var lastIsFocused = false
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}
