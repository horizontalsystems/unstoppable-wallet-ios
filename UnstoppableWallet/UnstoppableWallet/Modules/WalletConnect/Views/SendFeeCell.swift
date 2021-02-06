import UIKit
import RxSwift
import RxCocoa

protocol ISendFeeViewModel {
    var estimatedFeeDriver: Driver<String> { get }
    var feeDriver: Driver<String> { get }
}

class SendFeeCell: AdditionalDataCellNew {
    private let disposeBag = DisposeBag()

    init(viewModel: ISendFeeViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        title = "send.fee".localized

        viewModel.feeDriver
                .drive(onNext: { [weak self] status in
                    self?.value = status
                })
                .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class SendEstimatedFeeCell: AdditionalDataCellNew {
    private let disposeBag = DisposeBag()

    init(viewModel: ISendFeeViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        title = "send.estimated_fee".localized

        viewModel.estimatedFeeDriver
                .drive(onNext: { [weak self] status in
                    self?.value = status
                })
                .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class SendMaxFeeCell: AdditionalDataCellNew {
    private let disposeBag = DisposeBag()

    init(viewModel: ISendFeeViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        title = "send.max_fee".localized

        viewModel.feeDriver
                .drive(onNext: { [weak self] status in
                    self?.value = status
                })
                .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
