import UIKit
import ThemeKit
import RxSwift

class SwapCoinCard: UIView {
    private static let insets = UIEdgeInsets.zero

    private let disposeBag = DisposeBag()

    private let viewModel: BaseSwapInputViewModel
    weak var presentDelegate: IPresentDelegate?

    private let cardView = CardView(insets: SwapCoinCard.insets)

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()
    private let paddingView = UIView()
    private let tokenSelectButton = UIButton()

    private let inputFieldWrapper = UIView()
    private let inputField = UITextField()

    private let balanceView = AdditionalDataView()

    public init(viewModel: BaseSwapInputViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        cardView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.font = .body
        titleLabel.textColor = .themeOz

        cardView.addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(titleLabel)
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
        }

        badgeView.set(text: "swap.estimated".localized.uppercased())
        badgeView.isHidden = true

        cardView.addSubview(paddingView)
        paddingView.snp.makeConstraints { maker in
            maker.centerY.equalTo(badgeView)
            maker.leading.equalTo(badgeView.snp.trailing).offset(CGFloat.margin2x)
            maker.height.equalTo(10)
        }

        paddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        paddingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        cardView.addSubview(tokenSelectButton)
        tokenSelectButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
            maker.trailing.equalToSuperview()
            maker.leading.equalTo(paddingView.snp.trailing)
        }

        tokenSelectButton.setContentHuggingPriority(.required, for: .horizontal)
        tokenSelectButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        tokenSelectButton.semanticContentAttribute = .forceRightToLeft
        tokenSelectButton.setImage(UIImage(named: "Down")?.tinted(with: .themeGray), for: .normal)
        tokenSelectButton.setTitleColor(.themeLeah, for: .normal)
        tokenSelectButton.titleLabel?.font = UIFont.subhead1
        tokenSelectButton.addTarget(self, action: #selector(onTapTokenSelect), for: .touchUpInside)
        tokenSelectButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin6x, bottom: 0, right: .margin4x)
        tokenSelectButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -.margin2x, bottom: 0, right: .margin2x)

        cardView.addSubview(inputFieldWrapper)
        inputFieldWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tokenSelectButton.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        inputFieldWrapper.layer.cornerRadius = .cornerRadius2x
        inputFieldWrapper.layer.borderWidth = CGFloat.heightOnePixel
        inputFieldWrapper.layer.borderColor = UIColor.themeSteel20.cgColor

        inputFieldWrapper.addSubview(inputField)
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
                    self?.viewModel.onChange(amount: self?.inputField.text)
                })
                .disposed(by: disposeBag)

        cardView.addSubview(balanceView)
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
        subscribeToViewModel()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.description) { [weak self] in self?.set(title: $0) }
        subscribe(disposeBag, viewModel.isEstimated) { [weak self] in self?.setBadge(hidden: !$0) }
        subscribe(disposeBag, viewModel.amount) { [weak self] in self?.set(text: $0) }
        subscribe(disposeBag, viewModel.tokenCode) { [weak self] in self?.set(tokenCode: $0) }
        subscribe(disposeBag, viewModel.balance) { [weak self] in self?.set(balance: $0) }
        subscribe(disposeBag, viewModel.balanceError) { [weak self] in self?.set(balanceError: $0) }
    }

    @objc private func onTapTokenSelect() {
        let coins = viewModel.tokensForSelection

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
            tokenSelectButton.setTitle(tokenCode, for: .normal)
            tokenSelectButton.setTitleColor(.themeLeah, for: .normal)
        } else {
            tokenSelectButton.setTitle("swap.token".localized, for: .normal)
            tokenSelectButton.setTitleColor(.themeYellowD, for: .normal)
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

extension SwapCoinCard: ICoinSelectDelegate {

    func didSelect(coin: SwapModule.CoinBalanceItem) {
        viewModel.onSelect(coin: coin)
    }

}
