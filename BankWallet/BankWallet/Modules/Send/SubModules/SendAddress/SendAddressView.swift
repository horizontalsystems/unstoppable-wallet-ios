import UIKit
import RxSwift

class SendAddressView: UIView {
    private let addressInputField: AddressInputField
    private let delegate: ISendAddressViewDelegate

    public init(delegate: ISendAddressViewDelegate) {
        self.delegate = delegate
        addressInputField = AddressInputField(frame: .zero, placeholder: "send.address_placeholder".localized, showQrButton: true, canEdit: false, lineBreakMode: .byTruncatingMiddle)

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(SendTheme.margin)
        }
        addressInputField.onScan = { [weak self] in
            self?.delegate.onAddressScanClicked()
        }
        addressInputField.onPaste = { [weak self] in
            self?.delegate.onAddressPasteClicked()
        }
        addressInputField.onDelete = { [weak self] in
            self?.delegate.onAddressDeleteClicked()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}

extension SendAddressView: ISendAddressView {

    func set(address: String?, error: Error?) {
        addressInputField.bind(address: address, error: error)
    }

}
