import UIKit

class SendAddressCell: UITableViewCell {

    let addressInputField = AddressInputField(frame: .zero, placeholder: "send.address_placeholder".localized, showQrButton: true, canEdit: false, lineBreakMode: .byTruncatingMiddle)

    private var item: SAddressItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.holderTopMargin)
            maker.bottom.equalToSuperview()
        }
        addressInputField.onScan = { [weak self] in
            self?.item?.delegate?.onAddressScanClicked()
        }
        addressInputField.onPaste = { [weak self] in
            self?.item?.delegate?.onAddressPasteClicked()
        }
        addressInputField.onDelete = { [weak self] in
            self?.item?.delegate?.onAddressDeleteClicked()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: SAddressItem) {
        self.item = item
        item.bind = { [weak self] in
            self?.bind()
        }
        bind()
        addressInputField.bind(address: nil, error: nil)
    }

    private func set(addressInfo: AddressInfo?) {
    }

    func bind() {
        if let addressInfo = item?.addressInfo {
            switch addressInfo {
            case .address(let address):
                addressInputField.bind(address: address, error: nil)
            case .invalidAddress(let address, _):
                addressInputField.bind(address: address, error: "Invalid address")
            }
        } else {
            addressInputField.bind(address: nil, error: nil)
        }
    }

}
