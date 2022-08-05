import UIKit
import ThemeKit
import SnapKit
import RxSwift

class FormAmountInputView: UIView {
    private let viewModel: AmountInputViewModel
    private let disposeBag = DisposeBag()

    private let amountInputView = AmountInputView()

    init(viewModel: AmountInputViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(amountInputView)
        amountInputView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        amountInputView.isValidText = { [weak self] in self?.viewModel.isValid(amount: $0) ?? true }
        amountInputView.onChangeText = { [weak self] in self?.viewModel.onChange(amount: $0) }
        amountInputView.onTapMax = { [weak self] in self?.viewModel.onTapMax() }
        amountInputView.onTapSecondary = { [weak self] in self?.viewModel.onSwitch() }

        subscribe(disposeBag, viewModel.prefixDriver) { [weak self] in self?.set(prefix: $0) }
        subscribe(disposeBag, viewModel.amountDriver) { [weak self] in self?.set(amount: $0) }
        subscribe(disposeBag, viewModel.amountWarningDriver) { [weak self] in self?.set(amountWarning: $0) }
        subscribe(disposeBag, viewModel.isMaxEnabledDriver) { [weak self] in self?.amountInputView.maxButtonVisible = $0 }
        subscribe(disposeBag, viewModel.switchEnabledDriver) { [weak self] in self?.amountInputView.secondaryButtonEnabled = $0 }
        subscribe(disposeBag, viewModel.secondaryTextDriver) { [weak self] in self?.set(secondaryText: $0) }

        subscribe(disposeBag, viewModel.prefixTypeDriver) { [weak self] in self?.amountInputView.prefixColor = self?.textColor(inputType: $0) }
        subscribe(disposeBag, viewModel.amountTypeDriver) { [weak self] in self?.amountInputView.textColor = self?.textColor(inputType: $0) }
        subscribe(disposeBag, viewModel.secondaryTextTypeDriver) { [weak self] in self?.amountInputView.secondaryButtonTextColor = self?.textColor(inputType: $0) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        amountInputView.becomeFirstResponder()
    }

    private func set(amount: String?) {
        guard amountInputView.inputText != amount && !viewModel.equalValue(lhs: amountInputView.inputText, rhs: amount) else { //avoid issue with point ("1" and "1.")
            return
        }

        amountInputView.inputText = amount
    }

    private func set(amountWarning: String?) {
        amountInputView.warningText = amountWarning
    }

    private func textColor(inputType: AmountInputViewModel.InputType) -> UIColor {
        switch inputType {
        case .coin: return .themeLeah
        case .currency: return .themeJacob
        }
    }

    private func set(prefix: String?) {
        amountInputView.prefix = prefix
    }

    private func set(secondaryText: String?) {
        amountInputView.secondaryButtonText = secondaryText ?? "n/a".localized
    }

}

extension FormAmountInputView {

    var viewHeight: CGFloat {
        amountInputView.viewHeight
    }

    var editable: Bool {
        get { amountInputView.editable }
        set { amountInputView.editable = newValue }
    }

    var estimatedVisible: Bool {
        get { amountInputView.estimatedVisible }
        set { amountInputView.estimatedVisible = newValue }
    }

    var clearHidden: Bool {
        get { amountInputView.clearHidden }
        set { amountInputView.clearHidden = newValue }
    }

}

extension FormAmountInputView: IHeightControlView {

    var onChangeHeight: (() -> ())? {
        get { amountInputView.onChangeHeight }
        set { amountInputView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        amountInputView.height(containerWidth: containerWidth)
    }

}
