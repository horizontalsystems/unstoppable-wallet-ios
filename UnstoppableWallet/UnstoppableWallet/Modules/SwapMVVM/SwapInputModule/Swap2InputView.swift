import UIKit
import SnapKit
import RxSwift
import ThemeKit

class Swap2InputView: UIView {
    private var disposeBag = DisposeBag()

    private let presenter: ISwapInputPresenter

    private let holderView = UIView()

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()

    private let inputField = UITextField()
    private let maxButton = ThemeButton()
    private let tokenSelectButton = ThemeButton()

    public init(presenter: ISwapInputPresenter) {
        self.presenter = presenter

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(badgeView)
        addSubview(holderView)

        holderView.addSubview(inputField)
        holderView.addSubview(maxButton)
        holderView.addSubview(tokenSelectButton)

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
        }

        titleLabel.font = .body
        titleLabel.textColor = .themeOz

        badgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(titleLabel)
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
        }

        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin3x)
            maker.bottom.equalToSuperview()
        }
        holderView.layer.cornerRadius = CGFloat.cornerRadius2x
        holderView.layer.borderWidth = CGFloat.heightOneDp
        holderView.layer.borderColor = UIColor.themeSteel20.cgColor
        holderView.backgroundColor = .themeLawrence

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
                    self?.presenter.onChange(amount: self?.inputField.text)
                })
                .disposed(by: disposeBag)

        subscribeToPresenter()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func subscribeToPresenter() {
        subscribe(disposeBag, presenter.isEstimated) { [weak self] in self?.setBadge(hidden: !$0) }
        subscribe(disposeBag, presenter.amount) { [weak self] in self?.set(text: $0) }
        subscribe(disposeBag, presenter.tokenCode) { [weak self] in self?.set(tokenCode: $0) }
    }

    @objc private func onTapMax() {
//        delegate?.onMaxClicked(self)
    }

    @objc private func onTapTokenSelect() {
//        delegate?.onTokenSelectClicked(self)
    }

}

extension Swap2InputView {

    public func showKeyboard() {
        inputField.becomeFirstResponder()
    }

    public func set(title: String?) {
        titleLabel.text = title
    }

    public func setBadge(text: String?) {
        badgeView.set(text: text)
    }

    public func setBadge(hidden: Bool) {
        badgeView.isHidden = hidden
    }

    public func set(tokenCode: String?) {
        tokenSelectButton.setTitle(tokenCode, for: .normal)
    }

    public func set(text: String?) {
        inputField.text = text
    }

    public var text: String? {
        inputField.text
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

}

extension Swap2InputView: UITextFieldDelegate {

    private func validate(text: String) -> Bool {
        let isValid = presenter.isValid(amount: text)
        if !isValid {
            inputField.shakeView()
        }
        return isValid

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

}
