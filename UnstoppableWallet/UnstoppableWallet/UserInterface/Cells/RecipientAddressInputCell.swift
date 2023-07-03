import UIKit
import RxSwift

class RecipientAddressInputCell: AddressInputCell {
    private let viewModel: RecipientAddressViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: RecipientAddressViewModel) {
        self.viewModel = viewModel

        super.init()

        inputPlaceholder = "send.address_or_domain_placeholder".localized
        onChangeText = { [weak self] in self?.viewModel.onChange(text: $0) }
        onFetchText = { [weak self] in self?.viewModel.onFetch(text: $0) }
        onChangeEditing = { [weak self] in self?.viewModel.onChange(editing: $0) }
        onTapContacts = { [weak self] in self?.openContacts() }

        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] in
            self?.set(cautionType: $0?.type)
        }
        subscribe(disposeBag, viewModel.isSuccessDriver) { [weak self] in
            self?.set(isSuccess: $0)
        }
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in
            self?.set(isLoading: $0)
        }
        subscribe(disposeBag, viewModel.setTextDriver) { [weak self] in
            self?.inputText = $0
        }
        subscribe(disposeBag, viewModel.showContactsDriver) { [weak self] in
            self?.showContacts = $0
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func openContacts() {
        guard let blockchainType = viewModel.contactBlockchainType, let viewController = ContactBookModule.viewController(
                mode: .select(blockchainType, self),
                presented: true
        ) else {
            return
        }

        onOpenViewController?(viewController)
    }

    func set(inputText: String?) {
        self.inputText = inputText ?? ""
        viewModel.onChange(text: inputText)
    }

}

extension RecipientAddressInputCell: ContactBookSelectorDelegate {

    func onFetch(address: String) {
        set(inputText: address)
    }

}
