import UIKit
import SnapKit

class ReferenceInputField: UIView {

    var referenceInputField = UITextField()

    public init() {
        super.init(frame: .zero)
        backgroundColor = AppTheme.inputBackgroundColor
        borderWidth = SendTheme.inputBorderWidth
        borderColor = SendTheme.inputBorderColor
        cornerRadius = SendTheme.inputCornerRadius

        addSubview(referenceInputField)
        referenceInputField.autocorrectionType = .no
        referenceInputField.tintColor = SendTheme.inputTintColor
        referenceInputField.textColor = SendTheme.inputTextColor
        referenceInputField.font = SendTheme.inputFont
        referenceInputField.placeholder = "send.payment_reference_placeholder".localized

        referenceInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
