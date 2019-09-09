import UIKit
import SnapKit

class SendMemoView: UIView {
    private let delegate: ISendMemoViewDelegate

    private let holderView = UIView()
    private let memoInputField = UITextField()

    init(delegate: ISendMemoViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)

        backgroundColor = .clear

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.memoHeight)
        }

        addSubview(holderView)
        holderView.addSubview(memoInputField)

        holderView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.memoHolderTopMargin)
            maker.bottom.equalToSuperview()
        }

        holderView.layer.cornerRadius = SendTheme.holderCornerRadius

        holderView.layer.borderWidth = SendTheme.holderBorderWidth
        holderView.layer.borderColor = SendTheme.holderBorderColor.cgColor
        holderView.backgroundColor = SendTheme.holderBackground

        memoInputField.textColor = .crypto_Bars_Dark
        memoInputField.font = .cryptoSubheadItalic
        memoInputField.attributedPlaceholder = NSAttributedString(string: "send.confirmation.memo_placeholder".localized, attributes: [NSAttributedString.Key.foregroundColor: SendTheme.confirmationMemoPlaceholderColor])
        memoInputField.keyboardAppearance = App.theme.keyboardAppearance
        memoInputField.tintColor = SendTheme.confirmationMemoInputTintColor

        memoInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.memoInputFieldMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.memoInputFieldMargin)
            maker.centerY.equalToSuperview()
        }
        memoInputField.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}

extension SendMemoView: ISendMemoView {

    var memo: String? {
        return memoInputField.text
    }

}

extension SendMemoView: UITextFieldDelegate {

    private func validate(text: String) -> Bool {
        if delegate.validate(memo: text) {
            return true
        } else {
            memoInputField.shakeView()
            return false
        }
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = memoInputField.text, let textRange = Range(range, in: text) {
            let text = text.replacingCharacters(in: textRange, with: string)
            guard !text.isEmpty else {
                return true
            }
            return validate(text: text)
        }
        return validate(text: string)
    }

}
