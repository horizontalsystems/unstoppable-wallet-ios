import RxSwift
import UIKit

class RecipientAddressCautionCell: FormCautionCell {
    private let viewModel: RecipientAddressViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: RecipientAddressViewModel) {
        self.viewModel = viewModel

        super.init()

        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] in
            self?.set(caution: $0)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
