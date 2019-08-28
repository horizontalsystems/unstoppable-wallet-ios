import UIKit
import RxSwift

class SendAccountView: UIView {
    private let addressInputField: AddressInputField
    private let delegate: ISendAccountViewDelegate

    public init(delegate: ISendAccountViewDelegate) {
        self.delegate = delegate
        addressInputField = AddressInputField(frame: .zero, placeholder: "send.account_placeholder".localized, showQrButton: true, canEdit: true, lineBreakMode: .byTruncatingMiddle)

        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.addressHeight)
        }

        backgroundColor = .clear

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.height.equalTo(SendTheme.addressHolderHeight)
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
