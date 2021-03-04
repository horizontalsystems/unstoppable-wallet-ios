import UIKit
import ThemeKit
import SnapKit
import RxSwift

class AmountInputCell: UITableViewCell {
    private let viewModel: AmountInputViewModel
    private let disposeBag = DisposeBag()

    private let formValidatedView: FormValidatedView
    private let amountInputView = AmountInputView()

    init(viewModel: AmountInputViewModel) {
        self.viewModel = viewModel

        formValidatedView = FormValidatedView(contentView: amountInputView)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(formValidatedView)
        formValidatedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        amountInputView.isValidText = { [weak self] in self?.viewModel.isValid(amount: $0) ?? true }
        amountInputView.onChangeText = { [weak self] in self?.viewModel.onChange(amount: $0) }
        amountInputView.onTapMax = { [weak self] in self?.viewModel.onTapMax() }
        amountInputView.onTapSecondary = { [weak self] in self?.viewModel.onSwitch() }

        subscribe(disposeBag, viewModel.prefixDriver) { [weak self] in self?.set(prefix: $0) }
        subscribe(disposeBag, viewModel.amountDriver) { [weak self] in self?.set(amount: $0) }
        subscribe(disposeBag, viewModel.isMaxEnabledDriver) { [weak self] in self?.amountInputView.maxButtonVisible = $0 }
        subscribe(disposeBag, viewModel.switchEnabledDriver) { [weak self] in self?.amountInputView.secondaryButtonEnabled = $0 }
        subscribe(disposeBag, viewModel.secondaryTextDriver) { [weak self] in self?.set(secondaryText: $0) }
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

    private func set(prefix: String?) {
        amountInputView.prefix = prefix
    }

    private func set(secondaryText: String?) {
        amountInputView.secondaryButtonText = secondaryText ?? "n/a".localized
    }

}

extension AmountInputCell {

    var cellHeight: CGFloat {
        amountInputView.viewHeight
    }

    func set(cautionType: CautionType?) {
        formValidatedView.set(cautionType: cautionType)
    }

}
