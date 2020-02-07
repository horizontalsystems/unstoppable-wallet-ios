import UIKit
import RxSwift

class SendAccountView: UIView {
    private let addressInputField: AddressInputField
    private let delegate: ISendAccountViewDelegate

    public init(delegate: ISendAccountViewDelegate) {
        self.delegate = delegate
        addressInputField = AddressInputField(frame: .zero, placeholder: "send.account_placeholder".localized, showQrButton: true, canEdit: true, lineBreakMode: .byTruncatingMiddle)

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
        }
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
        addressInputField.bind(address: account, error: error)
    }

}
