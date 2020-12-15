import UIKit
import RxSwift

class SendAddressView: UIView {
    private let delegate: ISendAddressViewDelegate

    private let addressInputView = AddressInputView()
    private let cautionView = FormCautionView()

    public init(delegate: ISendAddressViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(addressInputView)
        addressInputView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(addressInputView.height(containerWidth: width))
        }

        addressInputView.inputPlaceholder = "send.address_placeholder".localized
        addressInputView.onOpenViewController = { [weak self] controller in
            self?.delegate.onOpenScan(controller: controller)
        }
        addressInputView.onChangeText = { [weak self] string in
            self?.delegate.onAddressChange(string: string?.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        addressInputView.onChangeHeight = { [weak self] in
            self?.updateInputHeight()
        }

        addSubview(cautionView)
        cautionView.snp.makeConstraints { maker in
            maker.top.equalTo(addressInputView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(cautionView.height(containerWidth: width))
        }

        cautionView.onChangeHeight = { [weak self] in
            self?.updateCautionHeight()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func updateInputHeight() {
        addressInputView.snp.updateConstraints { maker in
            maker.height.equalTo(addressInputView.height(containerWidth: width))
        }
    }

    private func updateCautionHeight() {
        cautionView.snp.updateConstraints { maker in
            maker.height.equalTo(cautionView.height(containerWidth: width))
        }
    }

}

extension SendAddressView: ISendAddressView {

    func set(error: Error?) {
        if let error = error {
            cautionView.set(caution: Caution(text: error.smartDescription, type: .error))
            addressInputView.set(cautionType: .error)
        } else {
            cautionView.set(caution: nil)
            addressInputView.set(cautionType: nil)
        }
    }

}
