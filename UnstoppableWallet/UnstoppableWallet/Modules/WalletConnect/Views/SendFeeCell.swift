import UIKit
import RxSwift
import RxCocoa

class SendFeeCell: AdditionalDataCellNew {
    private let disposeBag = DisposeBag()
    var titleType: TitleType = .fee {
        didSet {
            title = titleType.value
        }
    }

    init(driver: Driver<String?>) {
        super.init(style: .default, reuseIdentifier: nil)

        title = titleType.value

        driver
                .drive(onNext: { [weak self] status in
                    self?.isVisible = status != nil
                    self?.value = status
                })
                .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension SendFeeCell {

    enum TitleType {
        case fee
        case maxFee
        case estimatedFee

        var value: String {
            switch self {
            case .fee: return "send.network_fee".localized
            case .maxFee: return "send.max_fee".localized
            case .estimatedFee: return "send.estimated_fee".localized
            }
        }
    }

}
