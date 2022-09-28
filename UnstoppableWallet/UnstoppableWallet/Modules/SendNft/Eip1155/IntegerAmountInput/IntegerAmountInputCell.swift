import UIKit
import ThemeKit
import SnapKit

class IntegerAmountInputCell: UITableViewCell {
    private let formValidatedView: FormValidatedView
    private let formAmountInputView: IntegerFormAmountInputView

    init(viewModel: IntegerAmountInputViewModel) {
        formAmountInputView = IntegerFormAmountInputView(viewModel: viewModel)
        formValidatedView = FormValidatedView(contentView: formAmountInputView)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(formValidatedView)
        formValidatedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        formAmountInputView.becomeFirstResponder()
    }

}

extension IntegerAmountInputCell {

    var cellHeight: CGFloat {
        formAmountInputView.viewHeight
    }

    func set(cautionType: CautionType?) {
        formValidatedView.set(cautionType: cautionType)
    }

}
