import SnapKit
import ThemeKit
import UIKit

class StepperAmountInputCell: UITableViewCell {
    private let formValidatedView: FormValidatedView
    private let amountInputView: StepperAmountInputView

    init(allowFractionalNumbers: Bool) {
        amountInputView = StepperAmountInputView(allowFractionalNumbers: allowFractionalNumbers)
        formValidatedView = FormValidatedView(contentView: amountInputView)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(formValidatedView)
        formValidatedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        amountInputView.becomeFirstResponder()
    }
}

extension StepperAmountInputCell {
    var cellHeight: CGFloat {
        amountInputView.viewHeight
    }

    var value: Decimal? {
        get { amountInputView.value }
        set { amountInputView.value = newValue }
    }

    var onChangeValue: ((Decimal) -> Void)? {
        get { amountInputView.onChangeValue }
        set { amountInputView.onChangeValue = newValue }
    }

    func set(cautionType: CautionType?) {
        formValidatedView.set(cautionType: cautionType)
    }
}
