import SnapKit

import UIKit

class AmountInputCell: UITableViewCell {
    static let cornerRadius: CGFloat = .cornerRadius8

    private let formValidatedView: FormValidatedView
    private let formAmountInputView: FormAmountInputView

    init(viewModel: AmountInputViewModel) {
        formAmountInputView = FormAmountInputView(viewModel: viewModel)
        formValidatedView = FormValidatedView(contentView: formAmountInputView)
        formValidatedView.set(cornerRadius: AmountInputCell.cornerRadius)

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
        formAmountInputView.becomeFirstResponder()
    }
}

extension AmountInputCell {
    var cellHeight: CGFloat {
        formAmountInputView.viewHeight
    }

    func set(cautionType: CautionType?) {
        formValidatedView.set(cautionType: cautionType)
    }
}
