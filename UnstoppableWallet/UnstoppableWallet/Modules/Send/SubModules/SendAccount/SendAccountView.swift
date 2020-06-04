import UIKit
import RxSwift

class SendAccountView: UIView {
    private let addressInputField = InputField()
    private let delegate: ISendAccountViewDelegate

    public init(delegate: ISendAccountViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
        }

        addressInputField.placeholder = "send.account_placeholder".localized
        addressInputField.showQrButton = true

        addressInputField.onScan = { [weak self] in
            self?.delegate.onScanClicked()
        }
        addressInputField.onPaste = { [weak self] in
            self?.delegate.onPasteClicked()
        }
        addressInputField.onDelete = { [weak self] in
            self?.delegate.onDeleteClicked()
        }
        addressInputField.onTextChange = { [weak self] address in
            self?.delegate.onChange(account: address)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}

extension SendAccountView: ISendAccountView {

    func set(account: String?, error: Error?) {
        addressInputField.bind(text: account, error: error)
    }

}
