import UIKit
import ThemeKit
import RxSwift

class SwapCoinCardCell: UITableViewCell {
    let cellHeight: CGFloat = 160 + 2 * .margin12

    private let disposeBag = DisposeBag()

    private let viewModel: SwapCoinCardViewModel
    weak var presentDelegate: IPresentDelegate?

    private let cardView = CardView(insets: .zero)

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()
    private let paddingView = UIView()
    private let tokenSelectButton = UIButton()

    private let inputFieldWrapper = UIView()
    private let horizontalStackView = UIStackView()
    private let prefixLabel = UILabel()
    private let inputField = InputFieldStackView()
    private let switchButton = ThemeButton()
    private let secondaryInfoLabel = UILabel()

    private let balanceView = AdditionalDataView()

    public init(viewModel: SwapCoinCardViewModel, title: String) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        cardView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin12)
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.font = .body
        titleLabel.textColor = .themeOz
        titleLabel.text = title

        cardView.contentView.addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(titleLabel)
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin8)
        }

        badgeView.set(text: "swap.estimated".localized.uppercased())
        badgeView.isHidden = true

        cardView.contentView.addSubview(paddingView)
        paddingView.snp.makeConstraints { maker in
            maker.centerY.equalTo(badgeView)
            maker.leading.equalTo(badgeView.snp.trailing).offset(CGFloat.margin8)
            maker.height.equalTo(10)
        }

        paddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        paddingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        cardView.contentView.addSubview(tokenSelectButton)
        tokenSelectButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
            maker.trailing.equalToSuperview()
            maker.leading.equalTo(paddingView.snp.trailing)
        }

        tokenSelectButton.setContentHuggingPriority(.required, for: .horizontal)
        tokenSelectButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        tokenSelectButton.semanticContentAttribute = .forceRightToLeft
        tokenSelectButton.setImage(UIImage(named: "arrow_small_down_20"), for: .normal)
        tokenSelectButton.setTitleColor(.themeLeah, for: .normal)
        tokenSelectButton.titleLabel?.font = UIFont.subhead1
        tokenSelectButton.addTarget(self, action: #selector(onTapTokenSelect), for: .touchUpInside)
        tokenSelectButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin24, bottom: 0, right: .margin16)
        tokenSelectButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -.margin8, bottom: 0, right: .margin8)

        cardView.contentView.addSubview(inputFieldWrapper)
        inputFieldWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tokenSelectButton.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin8)
            maker.height.equalTo(75)
        }

        inputFieldWrapper.layer.cornerRadius = .cornerRadius2x
        inputFieldWrapper.layer.borderWidth = CGFloat.heightOnePixel
        inputFieldWrapper.layer.borderColor = UIColor.themeSteel20.cgColor

        inputFieldWrapper.addSubview(horizontalStackView)
        horizontalStackView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin8)
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        horizontalStackView.spacing = 0
        horizontalStackView.addArrangedSubview(prefixLabel)

        prefixLabel.font = .body
        prefixLabel.textColor = .themeLeah
        prefixLabel.setContentHuggingPriority(.required, for:.horizontal)
        prefixLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        horizontalStackView.addArrangedSubview(inputField)

        inputField.set(placeholder: "0", color: .themeGray50)
        inputField.onChangeText = { [weak self] text in
            self?.viewModel.onChange(amount: text)
        }
        inputField.isValidText = { [weak self] text in
            self?.viewModel.isValid(amount: text) ?? true
        }
        switchButton.apply(style: .secondaryIcon)
        switchButton.apply(secondaryIconImage: UIImage(named: "arrow_swap_20"))
        switchButton.addTarget(self, action: #selector(onTapSwitch), for: .touchUpInside)
        switchButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        inputField.append(view: switchButton)

        let separatorView = UIView()
        inputFieldWrapper.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin12)
            maker.trailing.equalToSuperview().inset(CGFloat.margin8)
            maker.top.equalTo(horizontalStackView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        inputFieldWrapper.addSubview(secondaryInfoLabel)
        secondaryInfoLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin12)
            maker.trailing.equalToSuperview().inset(CGFloat.margin8)
            maker.top.equalTo(separatorView.snp.bottom)
            maker.bottom.equalToSuperview()
        }

        secondaryInfoLabel.font = .caption
        secondaryInfoLabel.textColor = .themeLeah

        cardView.contentView.addSubview(balanceView)
        balanceView.snp.makeConstraints { maker in
            maker.top.equalTo(inputFieldWrapper.snp.bottom).offset(CGFloat.margin12)
            maker.leading.trailing.equalToSuperview()
        }

        subscribeToViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.isEstimated) { [weak self] in self?.setBadge(hidden: !$0) }
        subscribe(disposeBag, viewModel.prefixDriver) { [weak self] in self?.set(prefix: $0) }
        subscribe(disposeBag, viewModel.amountDriver) { [weak self] in self?.set(text: $0) }
        subscribe(disposeBag, viewModel.switchEnabledDriver) { [weak self] in self?.switchButton.isEnabled = $0 }
        subscribe(disposeBag, viewModel.secondaryInfoDriver) { [weak self] in self?.set(secondaryInfo: $0) }
        subscribe(disposeBag, viewModel.tokenCodeDriver) { [weak self] in self?.set(tokenCode: $0) }
        subscribe(disposeBag, viewModel.balanceDriver) { [weak self] in self?.set(balance: $0) }
        subscribe(disposeBag, viewModel.balanceErrorDriver) { [weak self] in self?.set(balanceError: $0) }
    }

    @objc private func onTapTokenSelect() {
        let viewController = CoinSelectModule.viewController(delegate: self)
        presentDelegate?.show(viewController: ThemeNavigationController(rootViewController: viewController))
    }

    @objc private func onTapSwitch() {
        viewModel.onSwitch()
    }

}

extension SwapCoinCardCell {

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
        guard inputField.text != text && !viewModel.equalValue(lhs: inputField.text, rhs: text) else { //avoid issue with point ("1" and "1.")
            return
        }

        inputField.set(text: text)
    }

    private func set(prefix: String?) {
        prefixLabel.set(hidden: prefix == nil)
        prefixLabel.text = prefix
    }

    private func set(secondaryInfo: SwapCoinCardViewModel.SecondaryInfoViewItem?) {
        secondaryInfoLabel.text = secondaryInfo?.text
        if let type = secondaryInfo?.type {
            secondaryInfoLabel.textColor = type == .placeholder ? .themeGray50 : .themeLeah
        }
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

extension SwapCoinCardCell: ICoinSelectDelegate {

    func didSelect(coin: Coin) {
        viewModel.onSelect(coin: coin)
    }

}
