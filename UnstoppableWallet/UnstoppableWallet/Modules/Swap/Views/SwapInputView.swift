import UIKit
import SnapKit
import RxSwift
import ThemeKit

class SwapInputView: UIView {
    weak var delegate: ISwapInputViewDelegate?

    private var disposeBag = DisposeBag()

    private let holderView = UIView()

    private let inputField = UITextField()
    private let maxButton = ThemeButton()
    private let tokenSelectButton = ThemeButton()

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        addSubview(holderView)

        holderView.addSubview(inputField)
        holderView.addSubview(maxButton)
        holderView.addSubview(tokenSelectButton)

        holderView.layer.cornerRadius = CGFloat.cornerRadius2x
        holderView.layer.borderWidth = CGFloat.heightOneDp
        holderView.layer.borderColor = UIColor.themeSteel20.cgColor
        holderView.backgroundColor = .themeLawrence
        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        maxButton.snp.makeConstraints { maker in //constraints need to be set on init
            maker.top.equalTo(tokenSelectButton.snp.top)
            maker.trailing.equalTo(tokenSelectButton.snp.leading).offset(-CGFloat.margin2x)
        }

        maxButton.apply(style: .secondaryDefault)
        maxButton.setContentHuggingPriority(.required, for: .horizontal)
        maxButton.setTitle("send.max_button".localized, for: .normal)
        maxButton.addTarget(self, action: #selector(onTapMax), for: .touchUpInside)

        inputField.delegate = self
        inputField.font = .body
        inputField.textColor = .themeOz
        inputField.attributedPlaceholder = NSAttributedString(string: "0", attributes: [NSAttributedString.Key.foregroundColor: UIColor.themeGray50])
        inputField.keyboardAppearance = .themeDefault
        inputField.keyboardType = .decimalPad
        inputField.tintColor = .themeInputFieldTintColor
        inputField.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.trailing.equalTo(maxButton.snp.leading).offset(-CGFloat.margin1x)
        }

        tokenSelectButton.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview().inset(CGFloat.margin2x)
        }

        tokenSelectButton.setContentHuggingPriority(.required, for: .horizontal)
        tokenSelectButton.apply(style: .secondaryDefault)
        tokenSelectButton.apply(secondaryIconImage: UIImage(named: "Token Drop Down")?.tinted(with: .themeLeah))
        tokenSelectButton.semanticContentAttribute = .forceRightToLeft
        tokenSelectButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 0)
        tokenSelectButton.addTarget(self, action: #selector(onTapTokenSelect), for: .touchUpInside)

        inputField.rx.controlEvent(.editingChanged)
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.willChangeAmount()
                })
                .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func willChangeAmount() {
        delegate?.willChangeAmount(self, text: inputField.text)
    }

    @objc private func onTapMax() {
        delegate?.onMaxClicked(self)
    }

    @objc private func onTapTokenSelect() {
        delegate?.onTokenSelectClicked(self)
    }

    private func format(coinValue: CoinValue) -> String? {
        decimalFormatter.maximumFractionDigits = min(coinValue.coin.decimal, 8)
        return decimalFormatter.string(from: coinValue.value as NSNumber)
    }


}

extension SwapInputView {

    public func showKeyboard() {
        inputField.becomeFirstResponder()
    }

    public func set(tokenCode: String) {
        tokenSelectButton.setTitle(tokenCode, for: .normal)
    }

    public func set(maxButtonVisible: Bool) {
        maxButton.snp.remakeConstraints { maker in
            if maxButtonVisible {
                maker.trailing.equalTo(tokenSelectButton.snp.leading).offset(-CGFloat.margin2x)
            } else {
                maker.trailing.equalTo(tokenSelectButton.snp.leading)
                maker.width.equalTo(0)
            }
            maker.top.equalToSuperview().inset(CGFloat.margin2x)
        }
    }

    public func set(text: String?) {
        inputField.text = text
    }

    public var text: String? {
        inputField.text
    }

}

extension SwapInputView: UITextFieldDelegate {

    private func validate(text: String) -> Bool {
        if let isValid = delegate?.isValid(self, text: text) {
            return isValid
        }

        inputField.shakeView()
        return false
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = inputField.text, let textRange = Range(range, in: text) {
            guard string != "" else {       // allow backspacing in inputView
                return true
            }
            let text = text.replacingCharacters(in: textRange, with: string)
            guard !text.isEmpty else {
                return true
            }
            return validate(text: text)
        }
        return validate(text: string)
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        print("textFieldDidBeginEditing")
    }

}
