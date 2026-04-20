import Combine
import SwiftUI

struct MnemonicInputCellWrapper: UIViewRepresentable {
    let statPage: StatPage
    let placeholder: String
    @Binding var invalidRanges: [NSRange]
    let cautionType: CautionType?
    let replaceWordPublisher: AnyPublisher<(NSRange, String), Never>
    @Binding var heightTrigger: Bool
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

        cell.onChangeMnemonicText = onChangeMnemonicText
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

    func updateUIView(_ uiView: MnemonicInputCell, context _: Context) {
        uiView.set(invalidRanges: invalidRanges)
        uiView.set(cautionType: cautionType)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MnemonicInputCell, context _: Context) -> CGSize? {
        let _ = heightTrigger
        let width = proposal.width ?? UIScreen.main.bounds.width
        return CGSize(width: width, height: uiView.cellHeight(containerWidth: width))
    }

    class Coordinator {
        var cancellable: AnyCancellable?
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
