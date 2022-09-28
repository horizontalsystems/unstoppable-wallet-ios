import UIKit
import ThemeKit
import SnapKit
import RxSwift

class IntegerFormAmountInputView: UIView {
    private let viewModel: IntegerAmountInputViewModel
    private let disposeBag = DisposeBag()

    private let amountInputView = IntegerAmountInputView()

    init(viewModel: IntegerAmountInputViewModel) {
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

        subscribe(disposeBag, viewModel.amountDriver) { [weak self] in self?.set(amount: $0) }
        subscribe(disposeBag, viewModel.isMaxEnabledDriver) { [weak self] in self?.amountInputView.maxButtonVisible = $0 }
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

}

extension IntegerFormAmountInputView {

    var viewHeight: CGFloat {
        amountInputView.viewHeight
    }

    var editable: Bool {
        get { amountInputView.editable }
        set { amountInputView.editable = newValue }
    }

    var clearHidden: Bool {
        get { amountInputView.clearHidden }
        set { amountInputView.clearHidden = newValue }
    }

}

extension IntegerFormAmountInputView: IHeightControlView {

    var onChangeHeight: (() -> ())? {
        get { amountInputView.onChangeHeight }
        set { amountInputView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        amountInputView.height(containerWidth: containerWidth)
    }

}
