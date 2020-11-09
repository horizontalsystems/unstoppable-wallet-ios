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

        addressInputField.openScan = { [weak self] controller in
            self?.delegate.onOpenScan(controller: controller)
        }
        addressInputField.onTextChange = { [weak self] string in
            self?.delegate.onAddressChange(string: string?.trimmingCharacters(in: .whitespaces))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}

extension SendAddressView: ISendAddressView {

    func set(error: Error?) {
        addressInputField.bind(error: error)
    }

}
