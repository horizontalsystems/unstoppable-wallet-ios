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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
