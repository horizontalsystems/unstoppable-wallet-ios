import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class IntegerAmountInputView: UIView {
    let viewHeight: CGFloat = 44

    private let inputStackView: InputStackView

    private let maxView = InputSecondaryButtonWrapperView(style: .default)
    private let clearView = InputSecondaryCircleButtonWrapperView()

    var maxButtonVisible = false {
        didSet {
            syncButtonStates()
        }
    }

    var clearHidden = false {
        didSet {
            syncButtonStates()
        }
    }

    var onChangeText: ((String?) -> Void)?
    var onTapMax: (() -> Void)?

    init(singleLine: Bool = false) {
        inputStackView = InputStackView(singleLine: singleLine)
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(inputStackView)
        inputStackView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        maxView.button.setTitle("send.max_button".localized, for: .normal)
        maxView.onTapButton = { [weak self] in self?.onTapMax?() }

        clearView.button.set(image: UIImage(named: "trash_20"))
        clearView.onTapButton = { [weak self] in
            self?.inputStackView.text = nil
            self?.handleChange(text: nil)
        }

        inputStackView.appendSubview(maxView)
        inputStackView.appendSubview(clearView)

        inputStackView.placeholder = "0"
        inputStackView.keyboardType = .decimalPad
        inputStackView.onChangeText = { [weak self] text in
            self?.handleChange(text: text)
        }

        syncButtonStates()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        inputStackView.becomeFirstResponder()
    }

    private func handleChange(text: String?) {
        onChangeText?(text)
        syncButtonStates()
    }

    private func syncButtonStates() {
        if let text = inputStackView.text, !text.isEmpty {
            maxView.isHidden = true
            clearView.isHidden = clearHidden
        } else {
            maxView.isHidden = !maxButtonVisible
            clearView.isHidden = true
        }
    }
}

extension IntegerAmountInputView {
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

    var isValidText: ((String) -> Bool)? {
        get { inputStackView.isValidText }
        set { inputStackView.isValidText = newValue }
    }

    var inputColor: UIColor? {
        get { inputStackView.textColor }
        set { inputStackView.textColor = newValue }
    }

    var editable: Bool {
        get { inputStackView.editable }
        set { inputStackView.editable = newValue }
    }
}

extension IntegerAmountInputView: IHeightControlView { // required in FormValidatedView, but not used yet
    var onChangeHeight: (() -> Void)? {
        get { nil }
        set {}
    }

    func height(containerWidth _: CGFloat) -> CGFloat {
        0
    }
}
