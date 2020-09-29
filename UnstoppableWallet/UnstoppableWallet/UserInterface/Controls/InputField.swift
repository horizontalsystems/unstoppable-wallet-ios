import UIKit
import SnapKit
import ThemeKit

class InputField: UIView {
    static private let textFont: UIFont = .body
    static private let textMargin: CGFloat = .margin3x
    static private let textHeight: CGFloat = InputField.textFont.lineHeight
    static private let errorTopMargin: CGFloat = .margin1x
    static private let buttonPadding: CGFloat = .margin2x
    static private let errorFont: UIFont = .caption

    private let wrapperView = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let errorLabel = UILabel()

    private let pasteButton = ThemeButton()
    private let deleteButton = ThemeButton()
    private let scanButton = ThemeButton()

    var showQrButton: Bool = false {
        didSet {
            scanButton.isHidden = !showQrButton
        }
    }

    var openScan: ((UIViewController) -> ())?
    var onTextChange: ((String?) -> ())?

    init() {
        super.init(frame: .zero)

        addSubview(wrapperView)

        wrapperView.addSubview(textView)
        textView.delegate = self
        textView.tintColor = .themeInputFieldTintColor
        textView.keyboardAppearance = .themeDefault
        textView.autocapitalizationType = .none
        textView.textContainer.maximumNumberOfLines = 1
        textView.textColor = .themeOz
        textView.font = .body
        textView.textContainer.lineBreakMode = .byTruncatingMiddle
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        textView.autocorrectionType = .no
        textView.isScrollEnabled = false

        wrapperView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { maker in
            maker.edges.equalTo(textView)
        }

        placeholderLabel.textColor = .themeGray50

        wrapperView.addSubview(errorLabel)
        errorLabel.font = InputField.errorFont
        errorLabel.textColor = .themeLucian
        errorLabel.numberOfLines = 0

        addSubview(pasteButton)
        pasteButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(InputField.buttonPadding)
            maker.centerY.equalToSuperview()
        }

        pasteButton.setContentHuggingPriority(.required, for: .horizontal)
        pasteButton.apply(style: .secondaryDefault)
        pasteButton.setTitle("button.paste".localized, for: .normal)
        pasteButton.addTarget(self, action: #selector(onTapPaste), for: .touchUpInside)

        addSubview(deleteButton)
        deleteButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(pasteButton)
            maker.centerY.equalTo(pasteButton.snp.centerY)
        }

        deleteButton.apply(style: .secondaryIcon)
        deleteButton.apply(secondaryIconImage: UIImage(named: "Send Delete Icon"))
        deleteButton.addTarget(self, action: #selector(onTapDelete), for: .touchUpInside)

        addSubview(scanButton)
        scanButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(pasteButton.snp.leading).offset(-InputField.buttonPadding)
            maker.centerY.equalTo(pasteButton.snp.centerY)
        }

        scanButton.apply(style: .secondaryIcon)
        scanButton.apply(secondaryIconImage: UIImage(named: "Send Scan Icon"))
        scanButton.isHidden = !showQrButton
        scanButton.addTarget(self, action: #selector(onTapScan), for: .touchUpInside)

        layer.cornerRadius = CGFloat.cornerRadius2x
        layer.borderWidth = 1
        layer.borderColor = UIColor.themeSteel20.cgColor
        backgroundColor = .themeLawrence

        bind(text: nil, error: nil)
    }

    @objc private func onTapPaste() {
        textView.text = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ")
        onTextChange?(textView.text)

        updateUi()
    }

    @objc private func onTapScan() {
        let scanQrViewController = ScanQrViewController()
        scanQrViewController.delegate = self
        openScan?(scanQrViewController)
    }

    @objc private func onTapDelete() {
        textView.text = nil
        onTextChange?(textView.text)

        updateUi()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var placeholder: String? {
        get {
            placeholderLabel.text
        }
        set {
            placeholderLabel.text = newValue
        }
    }

    var canEdit: Bool {
        get {
            textView.isUserInteractionEnabled
        }
        set {
            textView.isUserInteractionEnabled = newValue
        }
    }

    func bind(text: String?, error: Error?) {
        textView.text = text

        bind(error: error)
    }

    func bind(error: Error?) {
        if let error = error {
            errorLabel.isHidden = false
            errorLabel.text = error.smartDescription
            textView.snp.remakeConstraints { maker in
                maker.leading.top.trailing.equalToSuperview()
            }
            errorLabel.snp.remakeConstraints { maker in
                maker.top.equalTo(textView.snp.bottom).offset(InputField.errorTopMargin)
                maker.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            errorLabel.isHidden = true
            errorLabel.snp.removeConstraints()
            textView.snp.remakeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        }

        updateUi()
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    private func updateUi() {
        if let text = textView.text, !text.isEmpty {
            pasteButton.isHidden = true
            scanButton.isHidden = true
            deleteButton.isHidden = false
            placeholderLabel.isHidden = true

            wrapperView.snp.remakeConstraints { maker in
                maker.leading.top.bottom.equalToSuperview().inset(InputField.textMargin)
                maker.height.greaterThanOrEqualTo(InputField.textHeight)

                maker.trailing.equalTo(deleteButton.snp.leading).offset(-InputField.textMargin)
            }
        } else {
            pasteButton.isHidden = false
            scanButton.isHidden = false || !showQrButton
            deleteButton.isHidden = true
            placeholderLabel.isHidden = false

            wrapperView.snp.remakeConstraints { maker in
                maker.leading.top.bottom.equalToSuperview().inset(InputField.textMargin)
                maker.height.greaterThanOrEqualTo(InputField.textHeight)

                if showQrButton {
                    maker.trailing.equalTo(scanButton.snp.leading).offset(-InputField.textMargin)
                } else {
                    maker.trailing.equalTo(pasteButton.snp.leading).offset(-InputField.textMargin)
                }
            }
        }
    }

}

extension InputField: UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        onTextChange?(textView.text)

        updateUi()
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.contains(words: "\n") {
            return false
        }
        return true
    }

}

extension InputField {

    static func height(error: Error?, containerWidth: CGFloat) -> CGFloat {
        let deleteButtonWidth: CGFloat = 28
        let availableWidth = containerWidth - InputField.textMargin * 2 - deleteButtonWidth - InputField.buttonPadding

        var errorHeight = error?.smartDescription.height(forContainerWidth: availableWidth, font: InputField.errorFont)
        errorHeight = errorHeight.map { $0 + InputField.errorTopMargin }

        return InputField.textMargin * 2 + InputField.textHeight + (errorHeight ?? 0)
    }

}

extension InputField: IScanQrViewControllerDelegate {

    func didScan(string: String) {
        textView.text = string
        onTextChange?(textView.text)

        updateUi()
    }

}
