import Foundation
import UIKit
import RxSwift
import SnapKit
import ThemeKit
import ComponentKit
import MarketKit

class SwapInputCardView: UIView {
    static let lineHeight: CGFloat = 90
    private let amountInputHeight: CGFloat = 26
    private let descriptionHeight: CGFloat = 14

    private let disposeBag = DisposeBag()

    private let viewModel: SwapCoinCardViewModel
    private let amountInputViewModel: AmountInputViewModel

    weak var presentDelegate: IPresentDelegate?

    private let tokenSelectView = TokenSelectView()
    private let amountTextView = SingleLineFormTextView()
    private let secondaryView = UILabel()

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

        addSubview(amountTextView)
        amountTextView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().inset(25)
            maker.height.equalTo(amountInputHeight)
        }

        amountTextView.font = .headline1
        amountTextView.textColor = .themeLeah
        amountTextView.placeholder = "0.0"
        amountTextView.keyboardType = .decimalPad
        amountTextView.onChangeEditing = { [weak self] in self?.sync(editing: $0)  }

        addSubview(secondaryView)
        secondaryView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(amountTextView)
            maker.top.equalTo(amountTextView.snp.bottom).offset(3)
            maker.height.equalTo(descriptionHeight)
        }

        secondaryView.font = .caption
        secondaryView.textColor = .themeGray50

        addSubview(tokenSelectView)
        tokenSelectView.snp.makeConstraints { maker in
            maker.leading.equalTo(amountTextView.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().inset(22)
        }

        tokenSelectView.setContentHuggingPriority(.required, for: .horizontal)
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
        subscribe(disposeBag, viewModel.isDimmedDriver) { [weak self] in self?.set(dimmed: $0) }
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in self?.set(loading: $0) }

        subscribe(disposeBag, viewModel.balanceDriver) { [weak self] in self?.sync(balance: $0) }

        amountTextView.isValidText = { [weak self] in self?.amountInputViewModel.isValid(amount: $0) ?? true }
        amountTextView.onChangeText = { [weak self] in self?.amountInputViewModel.onChange(amount: $0) }

        subscribe(disposeBag, amountInputViewModel.prefixDriver) { [weak self] in self?.set(prefix: $0) }
        subscribe(disposeBag, amountInputViewModel.amountDriver) { [weak self] in self?.set(amount: $0) }
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

    private func sync(editing: Bool) {
        viewModel.viewIsEditing = editing
    }

}

extension SwapInputCardView {

    private func set(readOnly: Bool) {
        amountTextView.isEditable = !readOnly
    }

    private func set(dimmed: Bool) {
        amountTextView.textColor = dimmed ? .themeGray : .themeLeah
    }

    private func set(loading: Bool) {
        secondaryView.textColor = loading ? .themeGray50 : .themeGray
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
        amountTextView.endEditing(true)
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
