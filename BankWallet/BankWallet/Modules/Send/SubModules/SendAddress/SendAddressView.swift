import UIKit
import RxSwift

class SendAddressView: UIView {
    private let addressInputField = AddressInputField(frame: .zero, placeholder: "send.address_placeholder".localized, showQrButton: true, canEdit: false, lineBreakMode: .byTruncatingMiddle)
    private let delegate: ISendAddressViewDelegate

    public init(delegate: ISendAddressViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.addressHeight)
        }

        backgroundColor = .clear

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.holderTopMargin)
            maker.bottom.equalToSuperview()
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

    func set(address: String?, error: String?) {
        addressInputField.bind(address: address, error: error)
    }

}
