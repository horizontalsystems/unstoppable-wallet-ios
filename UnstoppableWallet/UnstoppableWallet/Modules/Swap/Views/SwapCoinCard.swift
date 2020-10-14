import UIKit
import ThemeKit
import RxSwift

class SwapCoinCard: UIView {
    private static let insets = UIEdgeInsets.zero

    private let disposeBag = DisposeBag()

    private let presenter: BaseSwapInputPresenter
    weak var presentDelegate: IPresentDelegate?

    private let cardView = CardView(insets: SwapCoinCard.insets)

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()
    private let paddingView = UIView()
    private let tokenSelectView = RightSelectableValueView()

    private let inputFieldWrapper = UIView()
    private let inputField = UITextField()

    private let balanceView = AdditionalDataView()

    public init(presenter: BaseSwapInputPresenter) {
        self.presenter = presenter

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(badgeView)
        cardView.addSubview(paddingView)
        cardView.addSubview(tokenSelectView)
        cardView.addSubview(inputFieldWrapper)
        inputFieldWrapper.addSubview(inputField)
        cardView.addSubview(balanceView)

        cardView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.font = .body
        titleLabel.textColor = .themeOz

        badgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(titleLabel)
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
        }

        badgeView.set(text: "swap.estimated".localized.uppercased())
        badgeView.isHidden = true

        paddingView.snp.makeConstraints { maker in
            maker.centerY.equalTo(badgeView)
            maker.leading.equalTo(badgeView.snp.trailing).offset(CGFloat.margin2x)
            maker.height.equalTo(10)
        }

        paddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        paddingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        tokenSelectView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
            maker.trailing.equalToSuperview()
            maker.leading.equalTo(paddingView.snp.trailing)
        }

        tokenSelectView.action = { [weak self] in
            self?.tapTokenSelect()
        }

        inputFieldWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tokenSelectView.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        inputFieldWrapper.layer.cornerRadius = .cornerRadius2x
        inputFieldWrapper.layer.borderWidth = CGFloat.heightOnePixel
        inputFieldWrapper.layer.borderColor = UIColor.themeSteel20.cgColor

        inputField.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin3x)
        }

        inputField.delegate = self
        inputField.font = .body
        inputField.textColor = .themeOz
        inputField.attributedPlaceholder = NSAttributedString(string: "0", attributes: [NSAttributedString.Key.foregroundColor: UIColor.themeGray50])
        inputField.keyboardAppearance = .themeDefault
        inputField.keyboardType = .decimalPad
        inputField.tintColor = .themeInputFieldTintColor

        inputField.rx.controlEvent(.editingChanged)
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.presenter.onChange(amount: self?.inputField.text)
                })
                .disposed(by: disposeBag)

        balanceView.snp.makeConstraints { maker in
            maker.top.equalTo(inputFieldWrapper.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func viewDidLoad() {
        subscribeToPresenter()
    }

    private func subscribeToPresenter() {
        subscribe(disposeBag, presenter.description) { [weak self] in self?.set(title: $0) }
        subscribe(disposeBag, presenter.isEstimated) { [weak self] in self?.setBadge(hidden: !$0) }
        subscribe(disposeBag, presenter.amount) { [weak self] in self?.set(text: $0) }
        subscribe(disposeBag, presenter.tokenCode) { [weak self] in self?.set(tokenCode: $0) }
        subscribe(disposeBag, presenter.balance) { [weak self] in self?.set(balance: $0) }
        subscribe(disposeBag, presenter.balanceError) { [weak self] in self?.set(balanceError: $0) }
    }

    private func tapTokenSelect() {
        let coins = presenter.tokensForSelection

        let vc = CoinSelectModule.instance(coins: coins, delegate: self)
        presentDelegate?.show(viewController: vc)
    }

}

extension SwapCoinCard {

    private func set(title: String?) {
        titleLabel.text = title?.localized
    }

    private func setBadge(hidden: Bool) {
        badgeView.isHidden = hidden
    }

    private func set(tokenCode: String?) {
        if let tokenCode = tokenCode {
            tokenSelectView.set(title: tokenCode)
            tokenSelectView.set(titleColor: .themeLeah)
        } else {
            tokenSelectView.set(title: "swap.token".localized)
            tokenSelectView.set(titleColor:  .themeYellowD)
        }
    }

    private func set(text: String?) {
        inputField.text = text
    }

    private func set(balance: String?) {
        balanceView.bind(title: "swap.balance".localized, value: balance)
    }

    private func set(balanceError: Bool) {
        let color: UIColor = balanceError ? .themeLucian : .themeGray
        balanceView.setTitle(color: color)
        balanceView.setValue(color: color)
    }

}

extension SwapCoinCard: UITextFieldDelegate {

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

extension SwapCoinCard: ICoinSelectDelegate {

    func didSelect(coin: SwapModule.CoinBalanceItem) {
        presenter.onSelect(coin: coin)
    }

}

