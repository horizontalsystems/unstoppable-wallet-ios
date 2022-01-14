import UIKit
import RxSwift

class SendAddressView: UIView {
    private let viewModel: RecipientAddressViewModel
    private let delegate: ISendAddressViewDelegate

    private let disposeBag = DisposeBag()

    private let addressInputView = AddressInputView()
    private let cautionView = FormCautionView()

    public init(viewModel: RecipientAddressViewModel, isResolutionEnabled: Bool, delegate: ISendAddressViewDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(addressInputView)
        addressInputView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(addressInputView.height(containerWidth: width))
        }

        addressInputView.inputPlaceholder = isResolutionEnabled ? "send.address_or_domain_placeholder".localized : "send.address_placeholder".localized
        addressInputView.onOpenViewController = { [weak self] controller in
            self?.delegate.onOpenScan(controller: controller)
        }
        addressInputView.onChangeText = { [weak self] string in
            self?.viewModel.onChange(text: string)
        }
        addressInputView.onFetchText = { [weak self] string in
            self?.viewModel.onFetch(text: string)
        }
        addressInputView.onChangeEditing = { [weak self] editing in
            self?.viewModel.onChange(editing: editing)
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

        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] in
            self?.addressInputView.set(cautionType: $0?.type)
            self?.cautionView.set(caution: $0)
        }
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in
            self?.addressInputView.set(isLoading: $0)
        }
        subscribe(disposeBag, viewModel.isSuccessDriver) { [weak self] in
            self?.addressInputView.set(isSuccess: $0)
        }
        subscribe(disposeBag, viewModel.setTextDriver) { [weak self] in
            self?.addressInputView.inputText = $0
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
