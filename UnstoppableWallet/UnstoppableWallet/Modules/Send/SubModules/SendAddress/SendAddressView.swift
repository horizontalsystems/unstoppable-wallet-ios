import UIKit
import RxSwift

class SendAddressView: UIView {
    private let addressInputField: InputField
    private let delegate: ISendAddressViewDelegate

    public init(delegate: ISendAddressViewDelegate) {
        self.delegate = delegate
        addressInputField = InputField()

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
        }

        addressInputField.placeholder = "send.address_placeholder".localized
        addressInputField.showQrButton = true
        addressInputField.canEdit = false

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
        addressInputField.bind(text: address, error: error)
    }

}
