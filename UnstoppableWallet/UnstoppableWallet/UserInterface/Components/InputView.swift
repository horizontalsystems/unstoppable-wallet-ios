import UIKit
import ThemeKit
import SnapKit

class InputView: UIView {
    private let formValidatedView: FormValidatedView
    private let inputStackView: InputStackView

    private let deleteView = InputSecondaryCircleButtonWrapperView()

    var onChangeText: ((String?) -> ())?

    var isEnabled: Bool = true {
        didSet {
            inputStackView.editable = isEnabled
            deleteView.button.isEnabled = isEnabled
        }
    }

    init(singleLine: Bool = false) {
        inputStackView = InputStackView(singleLine: singleLine)
        formValidatedView = FormValidatedView(contentView: inputStackView)

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(formValidatedView)
        formValidatedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        deleteView.button.set(image: UIImage(named: "trash_20"))
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

    override func becomeFirstResponder() -> Bool {
        inputStackView.becomeFirstResponder()
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
        } else {
            deleteView.isHidden = true
        }
    }

}

extension InputView {

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

    var textColor: UIColor? {
        get { inputStackView.textColor }
        set { inputStackView.textColor = newValue }
    }

    var font: UIFont? {
        get { inputStackView.font }
        set { inputStackView.font = newValue }
    }

    var accessoryEnabled: Bool {
        get { deleteView.button.isEnabled }
        set { deleteView.button.isEnabled = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { inputStackView.keyboardType }
        set { inputStackView.keyboardType = newValue }
    }

    var autocapitalizationType: UITextAutocapitalizationType {
        get { inputStackView.autocapitalizationType }
        set { inputStackView.autocapitalizationType = newValue }
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

    var isValidText: ((String) -> Bool)? {
        get { inputStackView.isValidText }
        set { inputStackView.isValidText = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        formValidatedView.height(containerWidth: containerWidth)
    }

}
