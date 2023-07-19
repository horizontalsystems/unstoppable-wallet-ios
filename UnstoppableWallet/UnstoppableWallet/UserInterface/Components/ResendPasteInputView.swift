import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class ResendPasteInputView: UIView {
    private let formValidatedView: FormValidatedView
    private let inputStackView = InputStackView()

    private let deleteView = InputSecondaryCircleButtonWrapperView()
    private let pasteView = InputSecondaryButtonWrapperView(style: .default)
    let resendView = InputSecondaryButtonWrapperView(style: .default)

    var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                inputStackView.isEditable = true
                inputStackView.textColor = .themeLeah
                deleteView.button.isEnabled = true
            } else {
                inputStackView.isEditable = false
                inputStackView.textColor = .themeGray
                deleteView.button.isEnabled = false
            }
        }
    }

    var onChangeText: ((String?) -> ())?
    var onFetchText: ((String?) -> ())?
    var onResend: (() -> ())?

    init() {
        formValidatedView = FormValidatedView(contentView: inputStackView, padding: UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16))

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(formValidatedView)
        formValidatedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        deleteView.button.set(image: UIImage(named: "trash_20"))
        deleteView.onTapButton = { [weak self] in self?.onTapDelete() }

        resendView.button.setTitle("button.resend".localized, for: .normal)
        resendView.onTapButton = { [weak self] in self?.onTapResend() }
        resendView.button.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        pasteView.button.setTitle("button.paste".localized, for: .normal)
        pasteView.onTapButton = { [weak self] in self?.onTapPaste() }
        pasteView.button.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        inputStackView.autocapitalizationType = .none
        inputStackView.autocorrectionType = .no

        inputStackView.appendSubview(deleteView)
        inputStackView.appendSubview(resendView)
        inputStackView.appendSubview(pasteView)

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

    private func onTapPaste() {
        guard let text = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ") else {
            return
        }

        onFetchText?(text)
    }

    private func onTapResend() {
        onResend?()
    }

    private func handleChange(text: String?) {
        onChangeText?(text)
        syncButtonStates()
    }

    private func syncButtonStates() {
        if let text = inputStackView.text, !text.isEmpty {
            deleteView.isHidden = false
            resendView.isHidden = true
            pasteView.isHidden = true
        } else {
            deleteView.isHidden = true
            resendView.isHidden = false
            pasteView.isHidden = false
        }
    }

}

extension ResendPasteInputView {

    var inputPlaceholder: String? {
        get { inputStackView.placeholder }
        set { inputStackView.placeholder = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { inputStackView.keyboardType }
        set { inputStackView.keyboardType = newValue }
    }

    var inputText: String? {
        get { inputStackView.text }
        set {
            inputStackView.text = newValue
            syncButtonStates()
        }
    }

    var isEditable: Bool {
        get { inputStackView.isEditable }
        set { inputStackView.isEditable = newValue }
    }

    func set(cautionType: CautionType?) {
        formValidatedView.set(cautionType: cautionType)
    }

    var onChangeEditing: ((Bool) -> ())? {
        get { inputStackView.onChangeEditing }
        set { inputStackView.onChangeEditing = newValue }
    }

    var onChangeHeight: (() -> ())? {
        get { formValidatedView.onChangeHeight }
        set { formValidatedView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        formValidatedView.height(containerWidth: containerWidth)
    }

}
