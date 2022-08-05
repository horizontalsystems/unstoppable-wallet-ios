import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class AmountInputView: UIView {
    let viewHeight: CGFloat = 85

    private let inputStackView: InputStackView
    private let separatorView = UIView()
    private let secondaryButton = UIButton()

    private let prefixView = InputPrefixWrapperView()
    private let estimatedView = InputBadgeWrapperView()
    private let maxView = InputSecondaryButtonWrapperView(style: .default)
    private let clearView = InputSecondaryCircleButtonWrapperView()
    private let warningView = UILabel()

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

    var onChangeText: ((String?) -> ())?
    var onTapMax: (() -> ())?
    var onTapSecondary: (() -> ())?

    init(singleLine: Bool = false) {
        inputStackView = InputStackView(singleLine: singleLine)
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(inputStackView)
        inputStackView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin8)
            maker.top.equalTo(inputStackView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        addSubview(secondaryButton)
        secondaryButton.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview()
            maker.top.equalTo(separatorView.snp.bottom)
        }

        secondaryButton.titleLabel?.font = .subhead2
        secondaryButton.contentHorizontalAlignment = .leading
        secondaryButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
        secondaryButton.setTitleColor(.themeBran, for: .normal)
        secondaryButton.setTitleColor(.themeGray50, for: .disabled)
        secondaryButton.addTarget(self, action: #selector(onTapSecondaryButton), for: .touchUpInside)

        addSubview(warningView)
        warningView.snp.makeConstraints { maker in
            maker.leading.equalTo(secondaryButton.snp.trailing).offset(CGFloat.margin12)
            maker.trailing.equalToSuperview().inset(CGFloat.margin8)
            maker.centerY.equalTo(secondaryButton.snp.centerY)
        }
        warningView.font = .caption
        warningView.textColor = .themeLucian
        warningView.isHidden = true

        prefixView.isHidden = true

        estimatedView.badgeView.text = "swap.estimated".localized.uppercased()
        estimatedVisible = false

        maxView.button.setTitle("send.max_button".localized, for: .normal)
        maxView.onTapButton = { [weak self] in self?.onTapMax?() }

        clearView.button.set(image: UIImage(named: "trash_20"))
        clearView.onTapButton = { [weak self] in
            self?.inputStackView.text = nil
            self?.handleChange(text: nil)
        }

        inputStackView.prependSubview(prefixView, customSpacing: .margin4)
        inputStackView.appendSubview(estimatedView)
        inputStackView.appendSubview(maxView)
        inputStackView.appendSubview(clearView)

        inputStackView.placeholder = "0"
        inputStackView.keyboardType = .decimalPad
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

    @objc private func onTapSecondaryButton() {
        onTapSecondary?()
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

extension AmountInputView {

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

    var prefix: String? {
        get { prefixView.label.text }
        set {
            prefixView.label.text = newValue
            prefixView.isHidden = newValue == nil
        }
    }

    var prefixColor: UIColor? {
        get { prefixView.textColor }
        set { prefixView.textColor = newValue }
    }


    var secondaryButtonText: String? {
        get { secondaryButton.title(for: .normal) }
        set { secondaryButton.setTitle(newValue, for: .normal) }
    }

    var secondaryButtonTextColor: UIColor? {
        get { secondaryButton.titleColor(for: .normal) }
        set { secondaryButton.setTitleColor(newValue, for: .normal) }
    }

    var secondaryButtonEnabled: Bool {
        get { secondaryButton.isEnabled }
        set { secondaryButton.isEnabled = newValue }
    }

     var estimatedVisible: Bool {
         get { estimatedView.isHidden }
         set { estimatedView.isHidden = !newValue }
     }

     var warningText: String? {
         get { warningView.text }
         set {
             warningView.text = newValue
             warningView.isHidden = (newValue == nil)
         }
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

extension AmountInputView: IHeightControlView { // required in FormValidatedView, but not used yet

    var onChangeHeight: (() -> ())? {
        get { nil }
        set {}
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        0
    }

}
