import Foundation
import UIKit
import RxSwift
import SnapKit
import ThemeKit
import ComponentKit
import MarketKit

class SwapInputCardView: UIView {
    static let lineHeight: CGFloat = 73.5
    private let amountInputHeight: CGFloat = 26
    private let descriptionHeight: CGFloat = 17

    private let disposeBag = DisposeBag()

    private let viewModel: SwapCoinCardViewModel
    private let amountInputViewModel: AmountInputViewModel

    weak var presentDelegate: IPresentDelegate?

    private let tokenSelectView = TokenSelectView()
    private let amountTextView = SingleLineFormTextView()
    private let secondaryView = UILabel()
    private let secondaryButton = UIButton()

    private var autocompleteView: SwapInputAccessoryView?

    override var inputAccessoryView: UIView? {
        autocompleteView
    }

    override var canBecomeFirstResponder: Bool {
        autocompleteView != nil
    }

    init(viewModel: SwapCoinCardViewModel, amountInputViewModel: AmountInputViewModel, isTopView: Bool) {
        self.viewModel = viewModel
        self.amountInputViewModel = amountInputViewModel

        super.init(frame: .zero)

        backgroundColor = .clear

        if isTopView {
            autocompleteView = SwapInputAccessoryView(frame: .zero)
            autocompleteView?.onSelect = { [weak self] multi in self?.setBalance(multi: multi)  }
        }

        addSubview(tokenSelectView)
        tokenSelectView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
            maker.height.equalTo(Self.lineHeight)
        }

        addSubview(amountTextView)
        amountTextView.snp.makeConstraints { maker in
            maker.leading.equalTo(tokenSelectView.snp.trailing)
            maker.top.equalToSuperview().inset(isTopView ? CGFloat.margin12: CGFloat.margin16)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(amountInputHeight)
        }

        amountTextView.font = .headline1
        amountTextView.textColor = .themeLeah
        amountTextView.placeholder = "0.0"
        amountTextView.textAlignment = .right
        amountTextView.keyboardType = .decimalPad
        amountTextView.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(secondaryView)
        secondaryView.snp.makeConstraints { maker in
            maker.leading.equalTo(tokenSelectView.snp.trailing)
            maker.top.equalTo(amountTextView.snp.bottom).offset(3)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(descriptionHeight)
        }

        secondaryView.font = .subhead2
        secondaryView.textColor = .themeGray
        secondaryView.textAlignment = .right

        addSubview(secondaryButton)
        secondaryButton.snp.makeConstraints { maker in
            maker.leading.equalTo(tokenSelectView.snp.trailing)
            maker.top.equalTo(amountTextView.snp.bottom).offset(3)
            maker.trailing.equalToSuperview()
            maker.bottom.equalTo(tokenSelectView.snp.bottom)
        }

        tokenSelectView.onTap = { [weak self] in self?.onTapTokenSelect() }

        subscribeToViewModel()
    }

    private func syncAutocompleteHeight() {
        let hasBalance = !(viewModel.balance ?? 0).isZero
        let hasAmount = !amountInputViewModel.amount.isZero
        let height: CGFloat = (!hasAmount && hasBalance) ? 44 : 0

        autocompleteView?.heightValue = height
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.readOnlyDriver) { [weak self] in self?.set(readOnly: $0) }
        subscribe(disposeBag, viewModel.tokenViewItemDriver) { [weak self] in self?.set(tokenViewItem: $0) }

        subscribe(disposeBag, viewModel.balanceDriver) { [weak self] in self?.sync(balance: $0) }

        amountTextView.isValidText = { [weak self] in self?.amountInputViewModel.isValid(amount: $0) ?? true }
        amountTextView.onChangeText = { [weak self] in self?.amountInputViewModel.onChange(amount: $0) }

        secondaryButton.addTarget(self, action: #selector(onTapSecondary), for: .touchUpInside)

        subscribe(disposeBag, amountInputViewModel.prefixDriver) { [weak self] in self?.set(prefix: $0) }
        subscribe(disposeBag, amountInputViewModel.amountDriver) { [weak self] in self?.set(amount: $0) }
        subscribe(disposeBag, amountInputViewModel.switchEnabledDriver) { [weak self] in self?.secondaryButton.isEnabled = $0 }
        subscribe(disposeBag, amountInputViewModel.secondaryTextDriver) { [weak self] in self?.set(secondaryText: $0) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        amountTextView.becomeFirstResponder()
    }

    private func onTapTokenSelect() {
        let viewController = CoinSelectModule.viewController(dex: viewModel.dex, delegate: self)
        presentDelegate?.present(viewController: ThemeNavigationController(rootViewController: viewController))
    }

    @objc private func onTapSecondary() {
        amountInputViewModel.onSwitch()
    }

}

extension SwapInputCardView {

    private func set(readOnly: Bool) {
        amountTextView.isEditable = !readOnly
    }

    private func set(tokenViewItem: SwapCoinCardViewModel.TokenViewItem?) {
        if let urlString = tokenViewItem?.iconUrlString {
            tokenSelectView.tokenImage.setImage(urlString: urlString, placeholder: tokenViewItem.flatMap { UIImage(named: $0.placeholderIconName) })
        } else {
            tokenSelectView.tokenImage.imageView.image = tokenViewItem.flatMap { UIImage(named: $0.placeholderIconName) } ?? UIImage(named: "placeholder_circle_32")
        }

        if let tokenViewItem = tokenViewItem {
            tokenSelectView.tokenButton.setTitle(tokenViewItem.title, for: .normal)
            tokenSelectView.tokenButton.setTitleColor(.themeLeah, for: .normal)
        } else {
            tokenSelectView.tokenButton.setTitle("swap.token".localized, for: .normal)
            tokenSelectView.tokenButton.setTitleColor(.themeYellowD, for: .normal)
        }
    }

    private func sync(balance: String?) {
        syncAutocompleteHeight()
    }

    private func set(prefix: String?) {
        amountTextView.prefix = prefix
    }

    private func set(amount: String?) {
        syncAutocompleteHeight()

        guard amountTextView.text != amount && !amountInputViewModel.equalValue(lhs: amountTextView.text, rhs: amount) else { //avoid issue with point ("1" and "1.")
            return
        }
        amountTextView.text = amount
    }

    private func setBalance(multi: Decimal) {
        amountInputViewModel.setBalance(multi: multi)
    }

    private func set(secondaryText: String?) {
        secondaryView.text = secondaryText
    }

}

extension SwapInputCardView: ICoinSelectDelegate {

    func didSelect(token: Token) {
        viewModel.onSelect(token: token)
    }

}
