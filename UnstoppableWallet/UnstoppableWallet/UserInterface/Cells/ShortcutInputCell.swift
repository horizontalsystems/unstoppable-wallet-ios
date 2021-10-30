import UIKit
import ThemeKit
import SnapKit

class ShortcutInputCell: UITableViewCell {
    private let formValidatedView: FormValidatedView
    private let inputStackView = InputStackView()

    private var shortcutViews = [InputButtonWrapperView]()
    private let deleteView = InputButtonWrapperView(style: .secondaryIcon)

    var onChangeText: ((String?) -> ())?

    init() {
        formValidatedView = FormValidatedView(contentView: inputStackView)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(formValidatedView)
        formValidatedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        deleteView.button.setImage(UIImage(named: "trash_20"), for: .normal)
        deleteView.onTapButton = { [weak self] in self?.onTapDelete() }

        inputStackView.appendSubview(deleteView)

        inputStackView.onChangeText = { [weak self] text in
            self?.handleChange(text: text)
        }

        syncButtonStates()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onTapDelete() {
        inputStackView.text = nil
        handleChange(text: nil)
    }

    private func handleChange(text: String?) {
        onChangeText?(text)
        syncButtonStates()
    }

    private func syncButtonStates() {
        if let text = inputStackView.text, !text.isEmpty {
            deleteView.isHidden = false
            shortcutViews.forEach { view in view.isHidden = true }
        } else {
            deleteView.isHidden = true
            shortcutViews.forEach { view in view.isHidden = false }
        }
    }

}

extension ShortcutInputCell {

    var inputPlaceholder: String? {
        get { inputStackView.placeholder }
        set { inputStackView.placeholder = newValue }
    }

    var inputText: String? {
        get { inputStackView.text }
        set {
            inputStackView.text = newValue
            syncButtonStates()
        }
    }

    var isEditable: Bool {
        get { inputStackView.isUserInteractionEnabled }
        set { inputStackView.isUserInteractionEnabled = newValue }
    }

    var maximumNumberOfLines: Int {
        get { inputStackView.maximumNumberOfLines }
        set { inputStackView.maximumNumberOfLines = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { inputStackView.keyboardType }
        set { inputStackView.keyboardType = newValue }
    }

    func set(cautionType: CautionType?) {
        formValidatedView.set(cautionType: cautionType)
    }

    func set(shortcuts: [InputShortcut]) {
        shortcutViews = shortcuts.map { shortcut in
            let view = InputButtonWrapperView(style: .secondaryDefault)

            view.button.setTitle(shortcut.title, for: .normal)
            view.onTapButton = { [weak self] in
                self?.inputStackView.text = shortcut.value
                self?.handleChange(text: shortcut.value)
            }

            inputStackView.appendSubview(view)

            return view
        }

        syncButtonStates()
    }

    var onChangeHeight: (() -> ())? {
        get { formValidatedView.onChangeHeight }
        set { formValidatedView.onChangeHeight = newValue }
    }

    var isValidText: ((String) -> Bool)? {
        get { inputStackView.isValidText }
        set { inputStackView.isValidText = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        formValidatedView.height(containerWidth: containerWidth)
    }

}

struct InputShortcut {
    let title: String
    let value: String
}
