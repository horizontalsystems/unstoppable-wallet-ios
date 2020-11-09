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

        addressInputField.openScan = { [weak self] controller in
            self?.delegate.onOpenScan(controller: controller)
        }
        addressInputField.onTextChange = { [weak self] address in
            self?.delegate.onChange(account: address?.trimmingCharacters(in: .whitespaces))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}

extension SendAccountView: ISendAccountView {

    func set(error: Error?) {
        addressInputField.bind(error: error)
    }

}
