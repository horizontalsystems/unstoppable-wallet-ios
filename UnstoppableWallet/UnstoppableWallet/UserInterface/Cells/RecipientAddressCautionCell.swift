import UIKit
import RxSwift

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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
