import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ThemeKit

class SwapInputView: UIView {
    private var disposeBag = DisposeBag()

    private let viewModel: BaseSwapInputViewModel
    weak var presentDelegate: IPresentDelegate?

    private let holderView = UIView()

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()

    private let inputField = UITextField()
    private let maxButton = ThemeButton()
    private let tokenSelectButton = ThemeButton()

    public init(viewModel: BaseSwapInputViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
        }

        titleLabel.font = .body
        titleLabel.textColor = .themeOz

        addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(titleLabel)
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
        }

        badgeView.set(text: "swap.estimated".localized.uppercased())
        badgeView.isHidden = true

        addSubview(holderView)
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

        holderView.addSubview(maxButton)
        maxButton.snp.makeConstraints { maker in //constraints need to be set on init
            maker.top.equalTo(tokenSelectButton.snp.top)
            maker.trailing.equalTo(tokenSelectButton.snp.leading).offset(-CGFloat.margin2x)
        }

        maxButton.apply(style: .secondaryDefault)
        maxButton.setContentHuggingPriority(.required, for: .horizontal)
        maxButton.setTitle("send.max_button".localized, for: .normal)
        maxButton.addTarget(self, action: #selector(onTapMax), for: .touchUpInside)


        holderView.addSubview(inputField)
        inputField.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.trailing.equalTo(maxButton.snp.leading).offset(-CGFloat.margin1x)
        }

        inputField.delegate = self
        inputField.font = .body
        inputField.textColor = .themeOz
        inputField.attributedPlaceholder = NSAttributedString(string: "0", attributes: [NSAttributedString.Key.foregroundColor: UIColor.themeGray50])
        inputField.keyboardAppearance = .themeDefault
        inputField.keyboardType = .decimalPad
        inputField.tintColor = .themeInputFieldTintColor

        holderView.addSubview(tokenSelectButton)
        tokenSelectButton.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview().inset(CGFloat.margin2x)
        }

        inputField.rx.controlEvent(.editingChanged)
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.viewModel.onChange(amount: self?.inputField.text)
                })
                .disposed(by: disposeBag)

        tokenSelectButton.setContentHuggingPriority(.required, for: .horizontal)
        tokenSelectButton.apply(style: .secondaryDefault)
        tokenSelectButton.apply(secondaryIconImage: UIImage(named: "Token Drop Down")?.tinted(with: .themeLeah))
        tokenSelectButton.semanticContentAttribute = .forceRightToLeft
        tokenSelectButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 0)
        tokenSelectButton.addTarget(self, action: #selector(onTapCoinSelect), for: .touchUpInside)

        set(maxButtonVisible: false)
        subscribeToViewModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.description) { [weak self] in self?.set(title: $0) }
        subscribe(disposeBag, viewModel.isEstimated) { [weak self] in self?.setBadge(hidden: !$0) }
        subscribe(disposeBag, viewModel.amount) { [weak self] in self?.set(text: $0) }
        subscribe(disposeBag, viewModel.tokenCode) { [weak self] in self?.set(tokenCode: $0) }
    }

    @objc private func onTapMax() {
//        delegate?.onMaxClicked(self)
    }

    @objc private func onTapCoinSelect() {
        let coins = viewModel.tokensForSelection

        let vc = CoinSelectModule.instance(coins: coins, delegate: self)
        presentDelegate?.show(viewController: vc)
    }

}

extension SwapInputView {

    private func set(title: String?) {
        titleLabel.text = title?.localized
    }

    private func setBadge(hidden: Bool) {
        badgeView.isHidden = hidden
    }

    private func set(tokenCode: String?) {
        tokenSelectButton.setTitle(tokenCode ?? "swap.token".localized, for: .normal)
    }

    private func set(text: String?) {
        inputField.text = text
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

extension SwapInputView: UITextFieldDelegate {

    private func validate(text: String) -> Bool {
        let isValid = viewModel.isValid(amount: text)
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

extension SwapInputView: ICoinSelectDelegate {

    func didSelect(coin: SwapModule.CoinBalanceItem) {
        viewModel.onSelect(coin: coin)
    }

}
